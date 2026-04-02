resource "aws_db_instance" "explicit_good" {
  engine = "mysql"
  instance_class = "db.t3.micro"
  engine_version = "8.0.0"
  iam_database_authentication_enabled = true
}

resource "aws_db_instance" "explicit_bad" {
  engine = "mysql"
  instance_class = "db.t3.micro"
  engine_version = "8.0.0"
  iam_database_authentication_enabled = "the_wrong_value"
}

resource "aws_db_instance" "implicit_bad" {
  engine = "mysql"
  engine_version = "8.0.0"
  instance_class = "db.t3.micro"
}

# PostgreSQL >= 10.0.0 - should be fixed
resource "aws_db_instance" "postgres_valid_version_missing" {
  engine = "postgres"
  engine_version = "13.11"
  instance_class = "db.t3.micro"
}

resource "aws_db_instance" "postgres_valid_version_explicit_false" {
  engine = "postgres"
  engine_version = "13.11"
  instance_class = "db.t3.micro"
  iam_database_authentication_enabled = false
}

# PostgreSQL < 10.0.0 - should be skipped
resource "aws_db_instance" "postgres_invalid_version_missing" {
  engine = "postgres"
  engine_version = "9.6.25"
  instance_class = "db.t3.micro"
}

resource "aws_db_instance" "postgres_invalid_version_explicit_false" {
  engine = "postgres"
  engine_version = "9.6.25"
  instance_class = "db.t3.micro"
  iam_database_authentication_enabled = false
}

# MariaDB >= 10.6.5 - should be fixed
resource "aws_db_instance" "mariadb_valid_version_missing" {
  engine = "mariadb"
  engine_version = "10.11.5"
  instance_class = "db.t3.micro"
}

resource "aws_db_instance" "mariadb_valid_version_explicit_false" {
  engine = "mariadb"
  engine_version = "10.11.5"
  instance_class = "db.t3.micro"
  iam_database_authentication_enabled = false
}

# MariaDB < 10.6.5 - should be skipped
resource "aws_db_instance" "mariadb_invalid_version_missing" {
  engine = "mariadb"
  engine_version = "10.5.0"
  instance_class = "db.t3.micro"
}

resource "aws_db_instance" "mariadb_invalid_version_explicit_false" {
  engine = "mariadb"
  engine_version = "10.5.0"
  instance_class = "db.t3.micro"
  iam_database_authentication_enabled = false
}

# Other engine (oracle) - should be skipped
resource "aws_db_instance" "oracle_engine_missing" {
  engine = "oracle-se2"
  engine_version = "19.0.0.0.ru-2023-10.rur-2023-10.r1"
  instance_class = "db.t3.micro"
}

resource "aws_db_instance" "oracle_engine_explicit_false" {
  engine = "oracle-se2"
  engine_version = "19.0.0.0.ru-2023-10.rur-2023-10.r1"
  instance_class = "db.t3.micro"
  iam_database_authentication_enabled = false
}
