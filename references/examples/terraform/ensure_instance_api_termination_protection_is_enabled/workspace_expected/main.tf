resource "aws_instance" "explicit_good" {
  dummy = "dummy"
  something = true
  foo = "bar"
  disable_api_termination = true
}

resource "aws_instance" "explicit_bad" {
  dummy = "dummy"
  something = true
  foo = "bar"
  disable_api_termination = true
}

resource "aws_instance" "implicit_bad" {
  dummy = "dummy"
  something = true
  foo = "bar"

  disable_api_termination = true
}
