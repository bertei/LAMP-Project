resource "aws_instance" "lamp-ec2" {
  ami           = var.ami
  instance_type = var.instance_type
  key_name      = data.aws_key_pair.lamp-keypair.key_name
  user_data     = file("${path.module}/scripts/user_data.sh")
  tags = {
    Name = "LAMP-EC2"
  }
}

data "aws_key_pair" "lamp-keypair" {
  key_name           = var.key_name
  include_public_key = true
}