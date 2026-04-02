resource "aws_db_instance" "postgres_iam_true" {
  allocated_storage    = 20
  engine               = "postgres"
  engine_version       = "14.10"
  instance_class       = "db.t3.micro"
  identifier           = "postgres-iam-true"
  username             = "admin"
  password             = "example-password"
  iam_database_authentication_enabled = true
  skip_final_snapshot  = true
}
