resource "aws_db_instance" "postgres_missing_iam" {
  allocated_storage    = 20
  engine               = "postgres"
  engine_version       = "13.11"
  instance_class       = "db.t3.micro"
  identifier           = "postgres-missing-iam"
  username             = "admin"
  password             = "example-password"
  skip_final_snapshot  = true

  iam_database_authentication_enabled = true
}
