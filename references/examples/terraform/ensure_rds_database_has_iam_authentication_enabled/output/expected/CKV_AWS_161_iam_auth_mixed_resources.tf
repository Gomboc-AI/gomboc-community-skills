terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}

resource "aws_db_instance" "no_iam_auth" {
  identifier                          = "no-iam-auth-db"
  allocated_storage                   = 20
  engine                              = "mysql"
  engine_version                      = "8.0"
  instance_class                      = "db.t3.micro"
  username                            = "user1"
  password                            = "password1!"
  parameter_group_name                = "default.mysql8.0"
  db_subnet_group_name                = "subnet-group-a"
  vpc_security_group_ids              = ["sg-00112233445566778"]
  skip_final_snapshot                 = true
  publicly_accessible                 = false
  deletion_protection                 = false
  iam_database_authentication_enabled = true
}

resource "aws_db_instance" "with_iam_auth" {
  identifier                          = "with-iam-auth-db"
  allocated_storage                   = 100
  engine                              = "mysql"
  engine_version                      = "8.0"
  instance_class                      = "db.t3.medium"
  username                            = "user2"
  password                            = "password2!"
  parameter_group_name                = "default.mysql8.0"
  db_subnet_group_name                = "subnet-group-b"
  vpc_security_group_ids              = ["sg-00aabbccddeeff001"]
  skip_final_snapshot                 = true
  publicly_accessible                 = false
  deletion_protection                 = true
  iam_database_authentication_enabled = true
}
