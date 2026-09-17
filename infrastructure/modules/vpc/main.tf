# VPC module
# Reusable regional VPC with DNS support enabled.
resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "${var.project}-vpc"
    Owner       = var.owner
    Project     = var.project
    Environment = var.environment
    "aws-apn-id" = var.aws_apn_id
  }
}
