resource "aws_instance" "explicit-good" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t3.micro"
  
  root_block_device {
    encrypted = true

    kms_key_id = "arn:aws:kms:us-east-1:111122223333:alias/my-cmk-key"
  }
}

resource "aws_instance" "explicit-bad" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t3.micro"
  
  root_block_device {
    encrypted = true

    kms_key_id = "arn:aws:kms:us-east-1:111122223333:alias/my-cmk-key"
  }
}

resource "aws_instance" "implicit-missing-block" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t3.micro"

  root_block_device {
    encrypted = true
    delete_on_termination = false

    kms_key_id = "arn:aws:kms:us-east-1:111122223333:alias/my-cmk-key"
  }
}

resource "aws_instance" "implicit-missing-encrypted-attribute" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t3.micro"

  root_block_device {
    volume_size = 10

    encrypted = true

    kms_key_id = "arn:aws:kms:us-east-1:111122223333:alias/my-cmk-key"
  }
}

resource "aws_instance" "implicit-empty-block" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t3.micro"

  root_block_device {
    encrypted = true

    kms_key_id = "arn:aws:kms:us-east-1:111122223333:alias/my-cmk-key"
  }
}
