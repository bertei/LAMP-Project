#Statefile managed manually. You have to manually create a bucket and define it in 'bucket' parameter.
terraform {
  backend "s3" {
    bucket = "rossx-lamp-challenge"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Environment = "Test"
      Name        = "Example"
      Managed-by  = "Terraform"
    }
  }
}

