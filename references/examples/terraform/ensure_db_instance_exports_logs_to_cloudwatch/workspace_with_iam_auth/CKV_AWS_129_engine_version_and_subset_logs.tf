resource "aws_db_instance" "mysql_versioned_subset" {
  allocated_storage           = 20
  engine                      = "mysql"
  engine_version              = "8.0.35"
  instance_class              = "db.t3.micro"
  identifier                  = "mysql-versioned-subset"
  username                    = "admin"
  password                    = "examplepassword"
  db_name                     = "exampledb"
  iam_database_authentication_enabled = true
  enabled_cloudwatch_logs_exports = [
    "error",
    "slowquery"
  ]
  skip_final_snapshot         = true
}

resource "aws_db_instance" "postgres_versioned_subset" {
  allocated_storage           = 20
  engine                      = "postgres"
  engine_version              = "15.4"
  instance_class              = "db.t3.micro"
  identifier                  = "postgres-versioned-subset"
  username                    = "admin"
  password                    = "examplepassword"
  db_name                     = "exampledb"
  iam_database_authentication_enabled = true
  enabled_cloudwatch_logs_exports = [
    "postgresql"
  ]
  skip_final_snapshot         = true
}
