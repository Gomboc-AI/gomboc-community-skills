terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-2"
}

resource "aws_db_instance" "complex" {
  identifier = "complex-db-instance"
  allocated_storage = 200
  max_allocated_storage = 500
  storage_type = "gp3"
  storage_encrypted = true
  kms_key_id = "arn:aws:kms:us-east-2:111122223333:key/12345678-1234-1234-1234-123456789012"
  engine = "mysql"
  engine_version = "8.0"
  instance_class = "db.m6g.large"
  username = "adminuser"
  password = "ComplexPassword123!"
  db_name = "maindb"
  multi_az = true
  backup_retention_period = 7
  preferred_backup_window = "03:00-04:00"
  maintenance_window = "sun:05:00-sun:06:00"
  auto_minor_version_upgrade = true
  deletion_protection = true
  performance_insights_enabled = true
  performance_insights_retention_period = 7
  monitoring_interval = 60
  monitoring_role_arn = "arn:aws:iam::111122223333:role/rds-monitoring-role"
  copy_tags_to_snapshot = true
  db_subnet_group_name = "complex-subnet-group"
  vpc_security_group_ids = ["sg-01230123012301230"]
  publicly_accessible = false
  enabled_cloudwatch_logs_exports = ["error", "slowquery"]
  skip_final_snapshot = false
  final_snapshot_identifier = "complex-db-instance-final"
  iam_database_authentication_enabled = true
}
