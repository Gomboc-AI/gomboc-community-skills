resource "aws_db_instance" "mysql_missing" {
  allocated_storage           = 20
  engine                      = "mysql"
  engine_version              = "8.0.35"
  instance_class              = "db.t3.micro"
  identifier                  = "mysql-mixed-missing"
  username                    = "admin"
  password                    = "examplepassword"
  db_name                     = "exampledb"
  skip_final_snapshot         = true
}

resource "aws_db_instance" "postgres_empty" {
  allocated_storage           = 20
  engine                      = "postgres"
  engine_version              = "14.10"
  instance_class              = "db.t3.micro"
  identifier                  = "postgres-mixed-empty"
  username                    = "admin"
  password                    = "examplepassword"
  db_name                     = "exampledb"
  enabled_cloudwatch_logs_exports = []
  skip_final_snapshot         = true
}

resource "aws_db_instance" "sqlserver_partial" {
  allocated_storage           = 20
  engine                      = "sqlserver-se"
  engine_version              = "15.00.4312.2.v1"
  instance_class              = "db.m5.large"
  identifier                  = "sqlserver-mixed-partial"
  username                    = "admin"
  password                    = "Examplepass123!"
  db_name                     = "exampledb"
  enabled_cloudwatch_logs_exports = [
    "agent"
  ]
  skip_final_snapshot         = true
}

resource "aws_db_instance" "oracle_compliant" {
  allocated_storage           = 20
  engine                      = "oracle-se2"
  engine_version              = "19.0.0.0.ru-2023-10.rur-2023-10.r1"
  instance_class              = "db.m5.large"
  identifier                  = "oracle-mixed-compliant"
  username                    = "admin"
  password                    = "Examplepass123!"
  db_name                     = "exampledb"
  enabled_cloudwatch_logs_exports = [
    "audit",
    "alert",
    "listener",
    "trace"
  ]
  skip_final_snapshot         = true
}

resource "aws_db_instance" "db2_compliant" {
  allocated_storage           = 100
  engine                      = "db2-se"
  engine_version              = "11.5.9.0"
  instance_class              = "db.m6i.large"
  identifier                  = "db2-mixed-compliant"
  username                    = "admin"
  password                    = "Examplepass123!"
  db_name                     = "exampledb"
  enabled_cloudwatch_logs_exports = [
    "diag.log",
    "notify.log"
  ]
  skip_final_snapshot         = true
}
