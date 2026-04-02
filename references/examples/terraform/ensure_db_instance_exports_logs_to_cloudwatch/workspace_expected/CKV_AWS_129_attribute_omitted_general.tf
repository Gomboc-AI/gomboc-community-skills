resource "aws_db_instance" "mysql_general" {
  allocated_storage           = 20
  engine                      = "mysql"
  engine_version              = "8.0.35"
  instance_class              = "db.t3.micro"
  identifier                  = "mysql-attribute-omitted"
  username                    = "admin"
  password                    = "examplepassword"
  db_name                     = "exampledb"
  skip_final_snapshot         = true

  enabled_cloudwatch_logs_exports = ["audit", "error", "slowquery"]
}
