resource "aws_db_instance" "custom_oracle_ignored" {
  allocated_storage    = 20
  engine               = "custom-oracle-ee"
  engine_version       = "19.0.0.0.ru-2023-10.rur-2023-10.r1"
  instance_class       = "db.m6i.large"
  identifier           = "custom-oracle-ignored"
  username             = "admin"
  password             = "example-password"
  iam_database_authentication_enabled = false
  skip_final_snapshot  = true
}
