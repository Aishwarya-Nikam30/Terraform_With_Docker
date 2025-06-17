provider "aws" {
 region = "eu-west-2"
}

# First declare the data source

data "aws_vpc" "default_vpc" {
  default = true
 }

# --- 1. Define the Security Group Resource ---
# This block creates a new security group.

resource "aws_security_group" "docker_ec2_sg" {
 name = "terraform-docker-ec2-sg"
 description = "Allow SSH and HTTP access for Terraform Docker EC2"

 # You need to specify the VPC ID where this security group should be created.
 # For many simple setups, it might be the default VPC.
 # You can find your default VPC ID in the AWS Console (VPC -> Your VPCs)
 # or dynamically using a data source:

 vpc_id = data.aws_vpc.default_vpc.id

 #ingress(Inbound)Rule
 ingress {
  description = "Allow HTTP from internet"
  from_port = 80
  to_port = 80
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  }
  
 ingress {
  description = "allow SSH from internet"
  from_port = 22
  to_port = 22
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  }

  # Egress (Outbound) Rules
 egress {
  from_port = 0
  to_port = 0
  protocol = "-1"    
  cidr_blocks = ["0.0.0.0/0"]
 }
 
 tags = {
  name = "TerraformDockerEC2SecurityGroup"
 }
}


resource "aws_instance" "docker_ec2" {
 ami = "ami-0798b19897c1257b7"
 instance_type = "t2.micro"
 key_name = "MobaKeyPair"

# --- 2. Attach the Security Group to the Instance ---
 vpc_security_group_ids = [aws_security_group.docker_ec2_sg.id]

# Install Docker via user_data script

 user_data = <<-EOF
            #!/bin/bash
	    yum update -y
	    amazon-linux-extras install docker -y
	    systemctl start docker
	    usermod -aG docker ec2-user && newgrp docker
	    docker run -dp 80:80 nginx
	    EOF

 tags = {
  name = "TerraformDockerEC2"
 }
}


output "instance_public_ip"{
 value = aws_instance.docker_ec2.public_ip
}
