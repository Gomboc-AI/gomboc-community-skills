data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["474230206603"]

  filter {
    name   = "name"
    values = ["ubuntu-bionic-1804-base-*"]
  }
}

resource "aws_instance" "valid" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
}
