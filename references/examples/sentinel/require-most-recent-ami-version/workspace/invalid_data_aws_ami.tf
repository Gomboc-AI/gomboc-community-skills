data "aws_ami" "missing_most_recent" {
  owners      = ["474230206603"]

  filter {
    name   = "name"
    values = ["ami-0480b2839381fe680"]
  }
}

data "aws_ami" "invalid_most_recent" {
  most_recent = false
  owners      = ["474230206603"]

  filter {
    name   = "name"
    values = ["ubuntu-bionic-1804-base-*"]
  }
}

data "aws_ami" "invalid_ami_pattern" {
  most_recent = true
  owners      = ["474230206603"]

  filter {
    name   = "name"
    values = ["*/ubuntu-jammy-daily-*"]
  }
}

data "aws_ami" "invalid_ami_owner" {
  most_recent = true
  owners      = ["483285841698"]

  filter {
    name   = "name"
    values = ["ami-0480b2839381fe680"]
  }
}

data "aws_ami" "no_name_filter" {
  most_recent = true
  owners      = ["474230206603"]
}
