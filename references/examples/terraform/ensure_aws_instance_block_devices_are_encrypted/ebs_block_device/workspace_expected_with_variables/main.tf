resource "aws_instance" "implicit-good" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t3.micro"
  
  root_block_device {
    encrypted = true

    kms_key_id = "arn:aws:kms:us-east-1:111122223333:alias/my-cmk-key"
  }
}

resource "aws_instance" "explicit-good" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t3.micro"
  
  root_block_device {
    encrypted = true

    kms_key_id = "arn:aws:kms:us-east-1:111122223333:alias/my-cmk-key"
  }

  ebs_block_device {
    device_name = "/dev/xvda"
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

  ebs_block_device {
    device_name = "/dev/xvda"
    encrypted = true

    kms_key_id = "arn:aws:kms:us-east-1:111122223333:alias/my-cmk-key"
  }
}

resource "aws_instance" "implicit-bad" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t3.micro"
  
  root_block_device {
    encrypted = true

    kms_key_id = "arn:aws:kms:us-east-1:111122223333:alias/my-cmk-key"
  }

  ebs_block_device {
    device_name = "/dev/xvda"

    encrypted = true

    kms_key_id = "arn:aws:kms:us-east-1:111122223333:alias/my-cmk-key"
  }
}

resource "aws_instance" "implicit-unknown" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t3.micro"
  
  root_block_device {
    encrypted = true

    kms_key_id = "arn:aws:kms:us-east-1:111122223333:alias/my-cmk-key"
  }

  ebs_block_device {
    device_name = "/dev/xvda"
    snapshot_id = "snap-01234567890abcdef0"
  }
}
