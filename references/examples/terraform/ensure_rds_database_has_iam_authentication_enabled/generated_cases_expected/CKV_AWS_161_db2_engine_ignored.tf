resource "aws_db_instance" "db2_ignored" {
  allocated_storage    = 20
  engine               = "db2-ae"
  engine_version       = "11.5.8.0"
  instance_class       = "db.m6i.large"
  identifier           = "db2-ae-ignored"
  username             = "admin"
  password             = "example-password"
  iam_database_authentication_enabled = true
  skip_final_snapshot  = true
}
