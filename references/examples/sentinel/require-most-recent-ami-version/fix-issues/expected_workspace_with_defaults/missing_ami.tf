data "aws_ami" "missing_ami" {
  most_recent = true
  owners      = ["474230206603"]

  filter {
    name   = "name"
    values = ["ubuntu-bionic-1804-base-*"]
  }
}
resource "aws_instance" "missing_ami" {
  instance_type = "t3.micro"

  ami = data.aws_ami.missing_ami.id
}
