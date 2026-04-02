resource "aws_db_instance" "mysql_iam_true" {
  allocated_storage    = 20
  engine               = "mysql"
  engine_version       = "5.7.44"
  instance_class       = "db.t3.micro"
  identifier           = "mysql-iam-true"
  username             = "admin"
  password             = "example-password"
  iam_database_authentication_enabled = true
  skip_final_snapshot  = true
}
