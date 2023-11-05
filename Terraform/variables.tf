variable "ami" {
  description = "AMI to utilize. Defaults to AMZ 2023 ami."
  type        = string
  default     = "ami-05c13eab67c5d8861"
}


variable "instance_type" {
  description = "Instance type. Defaults to t2.micro because of the free tier."
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "Key name. You must manually create a key-pair to be able to ssh into the ec2."
  type        = string
  default     = "berna-lamp"
}