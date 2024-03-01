# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

# Terraform configuration

provider "aws" {
  region = "us-east-1"
}



# Created with module
module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"

  name = "${var.ec2_name}-${var.env}"

  instance_type          = var.instance_type
  key_name               = var.key_name
  monitoring             = true
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.my_sg.id]
  subnet_id              = data.aws_subnet.selected_subnet.id

  tags = {
    Terraform   = "true"
    Environment = var.env
    Name        = "${var.ec2_name}-${var.env}-module"
  }
}

data "aws_vpc" "selected_vpc" {
  filter {
    name   = "tag:Name"
    values = [var.vpc_name]
  }
}

data "aws_subnet" "selected_subnet" {
  filter {
    name   = "tag:Name"
    values = [var.subnet_name]
  }
}

module "website_s3_bucket" {
  source = "./modules/aws-s3-static-website-bucket"

  bucket_name = "${var.bucket_name}-${var.env}"

  tags = {
    Terraform   = "true"
    Environment = "${var.env}"
  }
}

resource "aws_security_group" "my_sg" {
  name   = var.sg_name
  vpc_id = data.aws_vpc.selected_vpc.id # var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["103.252.202.165/32"]
  }

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

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}