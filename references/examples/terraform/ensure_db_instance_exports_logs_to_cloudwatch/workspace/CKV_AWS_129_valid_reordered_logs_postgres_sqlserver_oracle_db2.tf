resource "aws_db_instance" "postgres_db_reordered" {
  allocated_storage           = 20
  engine                      = "postgres"
  engine_version              = "14.10"
  instance_class              = "db.t3.micro"
  identifier                  = "postgres-reordered-logs"
  username                    = "admin"
  password                    = "examplepassword"
  db_name                     = "exampledb"
  enabled_cloudwatch_logs_exports = [
    "upgrade",
    "postgresql"
  ]
  skip_final_snapshot         = true
}

resource "aws_db_instance" "sqlserver_db_reordered" {
  allocated_storage           = 20
  engine                      = "sqlserver-ex"
  engine_version              = "15.00.4312.2.v1"
  instance_class              = "db.m5.large"
  identifier                  = "sqlserver-reordered-logs"
  username                    = "admin"
  password                    = "Examplepass123!"
  db_name                     = "exampledb"
  enabled_cloudwatch_logs_exports = [
    "error",
    "agent"
  ]
  skip_final_snapshot         = true
}

resource "aws_db_instance" "oracle_db_reordered" {
  allocated_storage           = 20
  engine                      = "oracle-se2"
  engine_version              = "19.0.0.0.ru-2023-10.rur-2023-10.r1"
  instance_class              = "db.m5.large"
  identifier                  = "oracle-reordered-logs"
  username                    = "admin"
  password                    = "Examplepass123!"
  db_name                     = "exampledb"
  enabled_cloudwatch_logs_exports = [
    "trace",
    "listener",
    "alert",
    "audit"
  ]
  skip_final_snapshot         = true
}

resource "aws_db_instance" "db2_db_reordered" {
  allocated_storage           = 100
  engine                      = "db2-se"
  engine_version              = "11.5.9.0"
  instance_class              = "db.m6i.large"
  identifier                  = "db2-reordered-logs"
  username                    = "admin"
  password                    = "Examplepass123!"
  db_name                     = "exampledb"
  enabled_cloudwatch_logs_exports = [
    "notify.log",
    "diag.log"
  ]
  skip_final_snapshot         = true
}
