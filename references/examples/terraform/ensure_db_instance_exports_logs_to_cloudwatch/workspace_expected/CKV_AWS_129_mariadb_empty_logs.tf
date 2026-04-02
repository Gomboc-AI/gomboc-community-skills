resource "aws_db_instance" "mariadb_db" {
  allocated_storage           = 20
  engine                      = "mariadb"
  engine_version              = "10.11.6"
  instance_class              = "db.t3.micro"
  identifier                  = "mariadb-empty-logs"
  username                    = "admin"
  password                    = "examplepassword"
  db_name                     = "exampledb"
  enabled_cloudwatch_logs_exports = ["audit", "error", "slowquery"]
  skip_final_snapshot         = true
}
