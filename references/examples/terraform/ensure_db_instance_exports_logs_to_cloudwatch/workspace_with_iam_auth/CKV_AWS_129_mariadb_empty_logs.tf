resource "aws_db_instance" "mariadb_db" {
  allocated_storage           = 20
  engine                      = "mariadb"
  engine_version              = "10.11.6"
  instance_class              = "db.t3.micro"
  identifier                  = "mariadb-empty-logs"
  username                    = "admin"
  password                    = "examplepassword"
  db_name                     = "exampledb"
  iam_database_authentication_enabled = true
  enabled_cloudwatch_logs_exports = []
  skip_final_snapshot         = true
}
