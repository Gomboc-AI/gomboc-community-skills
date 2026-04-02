resource "aws_instance" "explicit-good" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t3.micro"
  
  root_block_device {
    encrypted = true
  }
}

resource "aws_instance" "explicit-bad" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t3.micro"
  
  root_block_device {
    encrypted = false
  }
}

resource "aws_instance" "implicit-missing-block" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t3.micro"
}

resource "aws_instance" "implicit-missing-encrypted-attribute" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t3.micro"

  root_block_device {
    volume_size = 10
  }
}

resource "aws_instance" "implicit-empty-block" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t3.micro"

  root_block_device {}
}
