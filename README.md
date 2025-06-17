# Dockerized Nginx on AWS EC2 with Terraform

## 🌟 High-Level Overview

This project provides a straightforward guide to:

* **Provisioning an AWS EC2 instance** using Terraform.
* **Installing Docker** on the provisioned EC2 instance using a `user_data` script, or via manual SSH if preferred.
* **Running Docker commands** to deploy a container.
* **Optionally**, version-controlling your Terraform code with Git.

---

## 🚀 Final Outcome

Upon successful completion, you will have:

* Your **Terraform code (`main.tf`)** to provision the EC2 instance.
* An **EC2 instance running Docker** in your AWS account.
* A **Docker container (Nginx)** actively running on your EC2 instance.
* **Logs** of your Terraform operations for auditing.

---

## 🛠️ Tools Needed

Ensure you have the following tools set up on your local machine:

* ✅ **AWS Account:** With valid Access Key and Secret Key.
* ✅ **Terraform:** Installed on your local machine.
* ✅ **Git:** (Optional) For version control.
* ✅ **AWS CLI:** (Optional) Useful for verifying resources directly in AWS.

---

## 📝 STEP-BY-STEP GUIDE

Follow these steps to deploy your Dockerized Nginx instance.

### 1️⃣ Set Up AWS Credentials

Terraform requires your AWS credentials to create resources in your account. Choose one of the following methods:

**Option A: Export as Environment Variables (Temporary)**

Open your terminal and replace `YOUR_ACCESS_KEY`, `YOUR_SECRET_KEY`, and `us-east-1` with your actual values and desired AWS region. These are valid only for the current shell session.

```bash
export AWS_ACCESS_KEY_ID=YOUR_ACCESS_KEY
export AWS_SECRET_ACCESS_KEY=YOUR_SECRET_KEY
export AWS_DEFAULT_REGION=us-east-1

Or

[default]
aws_access_key_id = YOUR_ACCESS_KEY
aws_secret_access_key = YOUR_SECRET_KEY

2️⃣ Create Your Terraform Project Folder

```bash
mkdir terraform-docker-ec2
cd terraform-docker-ec2

3️⃣ Write main.tf
Create a file named main.tf inside your terraform-docker-ec2 folder and paste the following content.

Important Considerations:

The ami specified (ami-0c94855ba95c71c99) is an Amazon Linux 2 AMI. Verify its availability in eu-west-2 or update to a more recent Amazon Linux 2 AMI if needed.
Ensure the key_name ("your-keypair-name") matches an existing EC2 Key Pair in your AWS account within the eu-west-2 region. If it doesn't exist, Terraform will fail.

provider "aws" {
  region = "eu-west-2" # Ensure this matches your chosen region
}

# Define a Security Group to allow HTTP and SSH traffic
resource "aws_security_group" "docker_ec2_sg" {
  name        = "terraform-docker-ec2-sg"
  description = "Allow HTTP and SSH access for Terraform Docker EC2"

  # Look up the default VPC ID in your region
  data "aws_vpc" "default_vpc" {
    default = true
  }
  vpc_id = data.aws_vpc.default_vpc.id

  ingress {
    description = "Allow HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow SSH from internet (consider restricting to your IP)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # Allow all outbound traffic
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "TerraformDockerEC2SecurityGroup"
  }
}

resource "aws_instance" "docker_ec2" {
  ami           = "ami-0c94855ba95c71c99"  # Amazon Linux 2 AMI (update as per your region)
  instance_type = "t2.micro"
  key_name      = "your-keypair-name"      # IMPORTANT: Replace with your actual key pair name
  vpc_security_group_ids = [aws_security_group.docker_ec2_sg.id] # Attach the security group

  # Install Docker via user_data script
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              amazon-linux-extras install docker -y
              systemctl start docker
              usermod -a -G docker ec2-user
              docker run -d -p 80:80 nginx
              EOF

  tags = {
    Name = "TerraformDockerEC2"
  }
}

output "instance_public_ip" {
  value = aws_instance.docker_ec2.public_ip
}

4️⃣ Initialize Terraform
Navigate to your terraform-docker-ec2 folder in the terminal and run:
terraform init

5️⃣ Check the Plan
Before applying any changes, always review the execution plan to understand what Terraform will do:
terraform plan

6️⃣ Apply the Plan (Provision Infrastructure)
If the plan looks correct, proceed to provision your AWS infrastructure:
terraform apply

7️⃣ Verify Deployment
Once terraform apply completes:

👉 AWS Console: Go to your AWS Management Console, navigate to the EC2 service, and check your running instances. You should see an instance named TerraformDockerEC2.
👉 Nginx Web Page: Open your web browser and navigate to http://<public-ip>. You should see the Nginx welcome page, confirming that Docker is running and Nginx is accessible.

8️⃣ Check State
To view the resources Terraform is currently managing:
terraform state list

For detailed information about all managed resources:
terraform show

9️⃣ Destroy Infrastructure
When you are finished or no longer need the resources, it's crucial to clean them up to avoid incurring AWS costs:
terraform destroy

✅ Execution Logs
You can redirect the output of your Terraform commands to log files for easy review:
terraform apply | tee apply.log
terraform destroy | tee destroy.log


🌟 BONUS: Using Git
To version-control your Terraform code (highly recommended for any project):

git init
git add main.tf .gitignore # Remember to add .gitignore!
git commit -m "Initial Terraform code to provision Docker container on EC2"
# If pushing to GitHub for the first time:
# git branch -M main
# git remote add origin [https://github.com/your_username/your_repo_name.git](https://github.com/your_username/your_repo_name.git)
# git push -u origin main


💡 Key Notes
AWS Key Pair: Ensure the key_name in main.tf (e.g., MobaKeyPair) precisely matches an existing EC2 key pair in your eu-west-2 region. This is vital for SSH access.
user_data Script: This script automates the installation of Docker and the Nginx container upon instance boot.
Security Groups: The aws_security_group is fundamental for allowing necessary network access (HTTP on 80, SSH on 22). For production, consider restricting SSH access (currently 0.0.0.0/0) to specific trusted IP addresses for enhanced security.
AMI Version: The specified AMI ami-0c94855ba95c71c99 is an older Amazon Linux 2 AMI. For new deployments, it's often a good practice to use a data "aws_ami" block to dynamically fetch the latest Amazon Linux 2 AMI for your region, making your configuration more robust to future AMI updates.

📦 Final Deliverables
After completing these steps, you will have:

✅ Your main.tf file.
✅ (Optional) apply.log and destroy.log files with execution details.
