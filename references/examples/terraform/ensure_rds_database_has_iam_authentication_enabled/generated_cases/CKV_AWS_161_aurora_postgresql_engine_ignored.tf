resource "aws_db_instance" "aurora_postgresql_ignored" {
  allocated_storage    = 20
  engine               = "aurora-postgresql"
  engine_version       = "15.2"
  instance_class       = "db.r6g.large"
  identifier           = "aurora-postgresql-ignored"
  username             = "admin"
  password             = "example-password"
  iam_database_authentication_enabled = false
  skip_final_snapshot  = true
}
