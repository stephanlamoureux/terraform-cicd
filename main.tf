provider "aws" {
  region = "eu-central-1"
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  backend "s3" {
    bucket         = "tf-s3-state-stephan"
    key            = "tfstates/codeplatoon/s3demo.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "tf_dynmodb_state_lock"
    encrypt        = true
  }
}

data "aws_ami" "amazon_linux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-2023*-kernel-6.1-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["amazon"]
}

resource "aws_instance" "appserver" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.ec2OneSG.id}"]
  tags = {
    Name = "ec2OneSG-new"
  }
}

# Define the security group for public subnet
resource "aws_security_group" "ec2OneSG" {
  name        = "ec2sg-test_web"
  description = "Allow incoming HTTP connections & SSH access"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "ec2OneSG"
  }
}

output "instance_id" {
  description = "Instance ID"
  value       = aws_instance.appserver.id
}

output "instance_public_dns" {
  description = "Instance public dns"
  value       = aws_instance.appserver.public_dns
}
