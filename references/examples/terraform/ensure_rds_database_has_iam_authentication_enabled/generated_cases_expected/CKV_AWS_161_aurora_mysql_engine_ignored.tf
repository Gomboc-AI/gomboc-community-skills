resource "aws_db_instance" "aurora_mysql_ignored" {
  allocated_storage    = 20
  engine               = "aurora-mysql"
  engine_version       = "8.0.mysql_aurora.3.05.2"
  instance_class       = "db.r6g.large"
  identifier           = "aurora-mysql-ignored"
  username             = "admin"
  password             = "example-password"
  skip_final_snapshot  = true
}
