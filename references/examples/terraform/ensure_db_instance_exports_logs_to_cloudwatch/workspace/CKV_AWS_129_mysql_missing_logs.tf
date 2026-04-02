resource "aws_db_instance" "mysql_db" {
  allocated_storage    = 20
  engine               = "mysql"
  engine_version       = "8.0.35"
  instance_class       = "db.t3.micro"
  identifier           = "mysql-missing-logs"
  username             = "admin"
  password             = "examplepassword"
  db_name              = "exampledb"
  skip_final_snapshot  = true
}
