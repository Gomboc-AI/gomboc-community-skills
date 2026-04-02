terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-southeast-1"
}

resource "aws_db_instance" "db1" {
  identifier                          = "compliant-db-1"
  allocated_storage                   = 20
  engine                              = "mysql"
  engine_version                      = "8.0"
  instance_class                      = "db.t3.micro"
  username                            = "user1"
  password                            = "password1!"
  parameter_group_name                = "default.mysql8.0"
  db_subnet_group_name                = "subnet-group-1"
  vpc_security_group_ids              = ["sg-0aaabbbcccdddeee1"]
  skip_final_snapshot                 = true
  publicly_accessible                 = false
  deletion_protection                 = false
  iam_database_authentication_enabled = true
}

resource "aws_db_instance" "db2" {
  identifier                          = "compliant-db-2"
  allocated_storage                   = 100
  engine                              = "mysql"
  engine_version                      = "8.0"
  instance_class                      = "db.t3.small"
  username                            = "user2"
  password                            = "password2!"
  parameter_group_name                = "default.mysql8.0"
  db_subnet_group_name                = "subnet-group-2"
  vpc_security_group_ids              = ["sg-0aaabbbcccdddeee2"]
  skip_final_snapshot                 = true
  publicly_accessible                 = false
  deletion_protection                 = true
  iam_database_authentication_enabled = true
}
