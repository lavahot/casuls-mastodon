terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "us-west-1"
}

resource "aws_vpc" "casuls-social" {
  cidr_block = "10.0.0.0/16"
}
