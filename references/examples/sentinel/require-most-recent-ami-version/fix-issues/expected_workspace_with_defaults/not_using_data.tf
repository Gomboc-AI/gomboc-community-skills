data "aws_ami" "not_using_data" {
  most_recent = true
  owners      = ["474230206603"]

  filter {
    name   = "name"
    values = ["ubuntu-bionic-1804-base-*"]
  }
}
resource "aws_instance" "not_using_data" {
  ami           = data.aws_ami.not_using_data.id
  instance_type = "t3.micro"
}
