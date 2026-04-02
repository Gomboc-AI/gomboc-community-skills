resource "aws_db_instance" "mysql_iam_false" {
  allocated_storage    = 20
  engine               = "mysql"
  engine_version       = "8.0.35"
  instance_class       = "db.t3.micro"
  identifier           = "mysql-iam-false"
  username             = "admin"
  password             = "example-password"
  iam_database_authentication_enabled = false
  skip_final_snapshot  = true
}
