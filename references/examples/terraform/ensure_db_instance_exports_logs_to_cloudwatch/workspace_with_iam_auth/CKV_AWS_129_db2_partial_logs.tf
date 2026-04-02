resource "aws_db_instance" "db2_db" {
  allocated_storage           = 100
  engine                      = "db2-se"
  engine_version              = "11.5.9.0"
  instance_class              = "db.m6i.large"
  identifier                  = "db2-partial-logs"
  username                    = "admin"
  password                    = "Examplepass123!"
  db_name                     = "exampledb"
  iam_database_authentication_enabled = true
  enabled_cloudwatch_logs_exports = [
    "diag.log"
  ]
  skip_final_snapshot         = true
}
