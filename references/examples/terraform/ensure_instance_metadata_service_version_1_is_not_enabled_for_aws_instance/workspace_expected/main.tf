resource "aws_instance" "explicit-good-enabled" {
  ami           = "ami-12345678"
  instance_type = "t3.micro"

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
}

resource "aws_instance" "explicit-good-disabled" {
  ami           = "ami-12345678"
  instance_type = "t3.micro"

  metadata_options {
    http_endpoint = "disabled"
  }
}


resource "aws_instance" "implicit-good-enabled" {
  ami           = "ami-12345678"
  instance_type = "t3.micro"

  metadata_options {
    http_tokens   = "required"
  }
}

resource "aws_instance" "explicit-bad" {
  ami           = "ami-12345678"
  instance_type = "t3.micro"

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
}

resource "aws_instance" "explicit-bad" {
  ami           = "ami-12345678"
  instance_type = "t3.micro"

  metadata_options {
    http_tokens = "required"
  }
}


resource "aws_instance" "implicit-bad-empty-options" {
  ami           = "ami-12345678"
  instance_type = "t3.micro"

  metadata_options {
    http_tokens = "required"
  }
}

resource "aws_instance" "implicit-bad-missing-options" {
  ami           = "ami-12345678"
  instance_type = "t3.micro"

  metadata_options {
    http_tokens = "required"
  }
}

resource "aws_instance" "implicit-bad-options" {
  ami           = "ami-12345678"
  instance_type = "t3.micro"

  metadata_options {
    http_protocol_ipv6 = "enabled"

    http_tokens = "required"
  }
}
