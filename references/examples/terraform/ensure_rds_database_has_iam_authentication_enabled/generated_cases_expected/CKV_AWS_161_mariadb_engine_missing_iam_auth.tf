resource "aws_db_instance" "mariadb_ignored" {
  allocated_storage    = 20
  engine               = "mariadb"
  engine_version       = "10.11.5"
  instance_class       = "db.t3.micro"
  identifier           = "mariadb-ignored"
  username             = "admin"
  password             = "example-password"
  skip_final_snapshot  = true

  iam_database_authentication_enabled = true
}
