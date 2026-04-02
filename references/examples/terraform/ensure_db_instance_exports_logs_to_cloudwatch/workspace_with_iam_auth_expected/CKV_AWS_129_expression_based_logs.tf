resource "aws_db_instance" "mysql_expr" {
  allocated_storage           = 20
  engine                      = "mysql"
  engine_version              = "8.0.35"
  instance_class              = "db.t3.micro"
  identifier                  = "mysql-expression-logs"
  username                    = "admin"
  password                    = "examplepassword"
  db_name                     = "exampledb"
  iam_database_authentication_enabled = true
  enabled_cloudwatch_logs_exports = ["audit", "error", "slowquery", "iam-db-auth-error"]
  skip_final_snapshot         = true
}

resource "aws_db_instance" "postgres_expr" {
  allocated_storage           = 20
  engine                      = "postgres"
  engine_version              = "14.10"
  instance_class              = "db.t3.micro"
  identifier                  = "postgres-expression-logs"
  username                    = "admin"
  password                    = "examplepassword"
  db_name                     = "exampledb"
  iam_database_authentication_enabled = true
  skip_final_snapshot         = true

  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade", "iam-db-auth-error"]
}
