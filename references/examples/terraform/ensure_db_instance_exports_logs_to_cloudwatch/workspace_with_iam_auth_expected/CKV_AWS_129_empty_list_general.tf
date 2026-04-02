resource "aws_db_instance" "postgres_general" {
  allocated_storage           = 20
  engine                      = "postgres"
  engine_version              = "14.10"
  instance_class              = "db.t3.micro"
  identifier                  = "postgres-empty-list"
  username                    = "admin"
  password                    = "examplepassword"
  db_name                     = "exampledb"
  iam_database_authentication_enabled = true
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade", "iam-db-auth-error"]
  skip_final_snapshot         = true
}
