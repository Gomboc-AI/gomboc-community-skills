terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_db_instance" "basic" {
  identifier                         = "basic-db-instance"
  allocated_storage                  = 20
  engine                             = "mysql"
  engine_version                     = "8.0"
  instance_class                     = "db.t3.micro"
  username                           = "admin"
  password                           = "example-password"
  parameter_group_name               = "default.mysql8.0"
  db_subnet_group_name               = "example-subnet-group"
  vpc_security_group_ids             = ["sg-0123456789abcdef0"]
  skip_final_snapshot                = true
  publicly_accessible                = false
  deletion_protection                = false
  iam_database_authentication_enabled = true
}
