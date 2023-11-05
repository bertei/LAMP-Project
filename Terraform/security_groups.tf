resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = data.aws_security_group.default.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 22
  to_port     = 22
  ip_protocol = "tcp"
  description = "Allow ssh connections"
}

resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = data.aws_security_group.default.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"
  description = "Allow http connections"
}

resource "aws_vpc_security_group_ingress_rule" "https" {
  security_group_id = data.aws_security_group.default.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"
  description = "Allow https connections"
}

#Fetches default vpc
data "aws_vpc" "default" {
  default = true
}

data "aws_security_group" "default" {
  vpc_id = data.aws_vpc.default.id

  filter {
    name   = "group-name"
    values = ["default"]
  }
}