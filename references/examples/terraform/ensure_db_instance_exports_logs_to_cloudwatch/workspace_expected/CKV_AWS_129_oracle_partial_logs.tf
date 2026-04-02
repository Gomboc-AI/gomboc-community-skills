resource "aws_db_instance" "oracle_db" {
  allocated_storage           = 20
  engine                      = "oracle-ee"
  engine_version              = "19.0.0.0.ru-2023-10.rur-2023-10.r1"
  instance_class              = "db.m5.large"
  identifier                  = "oracle-partial-logs"
  username                    = "admin"
  password                    = "Examplepass123!"
  db_name                     = "exampledb"
  enabled_cloudwatch_logs_exports = ["alert", "audit", "listener", "trace"]
  skip_final_snapshot         = true
}
