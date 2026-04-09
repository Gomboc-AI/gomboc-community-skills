resource "aws_instance" "not_using_data" {
  ami           = "ami-0dcc1e21636832c5d"
  instance_type = "t3.micro"
}
