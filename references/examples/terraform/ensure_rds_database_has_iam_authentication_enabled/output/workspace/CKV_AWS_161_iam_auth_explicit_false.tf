terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

resource "aws_db_instance" "explicit_false" {
  identifier                          = "explicit-false-db"
  allocated_storage                   = 50
  engine                              = "mysql"
  engine_version                      = "8.0"
  instance_class                      = "db.t3.small"
  username                            = "dbadmin"
  password                            = "change-me-123"
  parameter_group_name                = "default.mysql8.0"
  db_subnet_group_name                = "prod-subnet-group"
  vpc_security_group_ids              = ["sg-0fedcba9876543210"]
  skip_final_snapshot                 = true
  publicly_accessible                 = false
  deletion_protection                 = true
  iam_database_authentication_enabled = false
}
