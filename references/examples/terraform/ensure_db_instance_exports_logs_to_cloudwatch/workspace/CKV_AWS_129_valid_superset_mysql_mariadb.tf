resource "aws_db_instance" "mysql_db_superset" {
  allocated_storage           = 20
  engine                      = "mysql"
  engine_version              = "8.0.35"
  instance_class              = "db.t3.micro"
  identifier                  = "mysql-superset-logs"
  username                    = "admin"
  password                    = "examplepassword"
  db_name                     = "exampledb"
  enabled_cloudwatch_logs_exports = [
    "audit",
    "error",
    "general",
    "slowquery"
  ]
  skip_final_snapshot         = true
}

resource "aws_db_instance" "mariadb_db_superset" {
  allocated_storage           = 20
  engine                      = "mariadb"
  engine_version              = "10.11.6"
  instance_class              = "db.t3.micro"
  identifier                  = "mariadb-superset-logs"
  username                    = "admin"
  password                    = "examplepassword"
  db_name                     = "exampledb"
  enabled_cloudwatch_logs_exports = [
    "general",
    "audit",
    "error",
    "slowquery"
  ]
  skip_final_snapshot         = true
}
