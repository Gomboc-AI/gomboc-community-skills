terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-west-1"
}

resource "aws_db_instance" "postgres_db" {
  identifier = "postgres-db-instance"
  allocated_storage = 20
  engine = "postgres"
  engine_version = "14.7"
  instance_class = "db.t4g.small"
  username = "pgadmin"
  password = "PgPassword123!"
  parameter_group_name = "default.postgres14"
  db_subnet_group_name = "postgres-subnet-group"
  vpc_security_group_ids = ["sg-0abcdeffedcba0123"]
  skip_final_snapshot = true
  publicly_accessible = false
  deletion_protection = true
  iam_database_authentication_enabled = true
}
