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
  region = "us-east-1"
}

# The green region reads the database password from SSM in its own region (eu-north-1),
# so the same password is also stored there.
provider "aws" {
  alias  = "eu_north_1"
  region = "eu-north-1"
}