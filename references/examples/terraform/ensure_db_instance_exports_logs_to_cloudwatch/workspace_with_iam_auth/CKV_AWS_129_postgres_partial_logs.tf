resource "aws_db_instance" "postgres_db" {
  allocated_storage           = 20
  engine                      = "postgres"
  engine_version              = "14.10"
  instance_class              = "db.t3.micro"
  identifier                  = "postgres-partial-logs"
  username                    = "admin"
  password                    = "examplepassword"
  db_name                     = "exampledb"
  enabled_cloudwatch_logs_exports = [
    "postgresql"
  ]
  iam_database_authentication_enabled = true
  skip_final_snapshot         = true
}
