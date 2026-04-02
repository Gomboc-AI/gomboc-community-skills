resource "aws_db_instance" "postgres_iam_false" {
  allocated_storage    = 20
  engine               = "postgres"
  engine_version       = "15.3"
  instance_class       = "db.t3.micro"
  identifier           = "postgres-iam-false"
  username             = "admin"
  password             = "example-password"
  iam_database_authentication_enabled = false
  skip_final_snapshot  = true
}
