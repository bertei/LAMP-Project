output "ec2_public_ip" {
  description = "EC2 Public ip"
  value = aws_instance.lamp-ec2.public_ip
}

output "ec2_public_dns" {
  description = "EC2 Public DNS"
  value = aws_instance.lamp-ec2.public_dns
}