resource "aws_db_instance" "custom_mysql" {
  allocated_storage           = 20
  engine                      = "custom-mysql"
  engine_version              = "8.0.35"
  instance_class              = "db.m5.large"
  identifier                  = "custom-mysql-instance"
  username                    = "admin"
  password                    = "examplepassword"
  db_name                     = "exampledb"
  iam_database_authentication_enabled = true
  skip_final_snapshot         = true
}

resource "aws_db_instance" "custom_oracle" {
  allocated_storage           = 20
  engine                      = "custom-oracle-ee"
  engine_version              = "19.0.0.0.ru-2023-10.rur-2023-10.r1"
  instance_class              = "db.m5.large"
  identifier                  = "custom-oracle-instance"
  username                    = "admin"
  password                    = "examplepassword"
  db_name                     = "exampledb"
  iam_database_authentication_enabled = true
  skip_final_snapshot         = true
}
