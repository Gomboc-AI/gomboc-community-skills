resource "aws_db_instance" "mysql_missing_iam" {
  allocated_storage    = 20
  engine               = "mysql"
  engine_version       = "8.0.35"
  instance_class       = "db.t3.micro"
  identifier           = "mysql-missing-iam"
  username             = "admin"
  password             = "example-password"
  skip_final_snapshot  = true

  iam_database_authentication_enabled = true
}
