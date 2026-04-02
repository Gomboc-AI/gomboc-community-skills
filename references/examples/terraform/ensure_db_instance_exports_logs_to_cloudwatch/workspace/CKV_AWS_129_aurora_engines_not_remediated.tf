resource "aws_db_instance" "aurora_mysql" {
  allocated_storage           = 20
  engine                      = "aurora-mysql"
  engine_version              = "8.0.mysql_aurora.3.05.2"
  instance_class              = "db.r6g.large"
  identifier                  = "aurora-mysql-instance"
  username                    = "admin"
  password                    = "examplepassword"
  db_name                     = "exampledb"
  skip_final_snapshot         = true
}

resource "aws_db_instance" "aurora_postgres" {
  allocated_storage           = 20
  engine                      = "aurora-postgresql"
  engine_version              = "15.2"
  instance_class              = "db.r6g.large"
  identifier                  = "aurora-postgres-instance"
  username                    = "admin"
  password                    = "examplepassword"
  db_name                     = "exampledb"
  skip_final_snapshot         = true
}
