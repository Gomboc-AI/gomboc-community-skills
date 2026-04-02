resource "aws_db_instance" "sqlserver_db" {
  allocated_storage           = 20
  engine                      = "sqlserver-se"
  engine_version              = "15.00.4312.2.v1"
  instance_class              = "db.m5.large"
  identifier                  = "sqlserver-partial-logs"
  username                    = "admin"
  password                    = "Examplepass123!"
  db_name                     = "exampledb"
  enabled_cloudwatch_logs_exports = ["agent", "error"]
  skip_final_snapshot         = true
}
