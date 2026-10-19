terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-north-1"
}

# The shared database VPC lives in us-east-1. This provider accepts the peering connection
# and adds the return route on that side.
provider "aws" {
  alias  = "data"
  region = "us-east-1"
}