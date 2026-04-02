resource "aws_db_instance" "snapshot_without_engine" {
  allocated_storage    = 20
  instance_class       = "db.t3.micro"
  identifier           = "snapshot-no-engine"
  snapshot_identifier  = "rds:example-snapshot-id"
  username             = "admin"
  password             = "example-password"
  skip_final_snapshot  = true
}
