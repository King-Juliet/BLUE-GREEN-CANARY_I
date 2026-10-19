locals {
  project     = "bluegreen-canary"
  environment = "shared"
  owner       = "platform-team"
  aws_apn_id  = "65jiyh5muw5om1whvryxkbpyd"
  aws_region  = "us-east-1"

  # CIDR of this stack's own VPC. It must not overlap the blue (10.10.0.0/16) or green (10.20.0.0/16) VPCs.
  vpc_cidr       = "10.30.0.0/16"
  blue_vpc_cidr  = "10.10.0.0/16"
  green_vpc_cidr = "10.20.0.0/16"

  # Same name in every region. The backend task in each region reads it from its own regional SSM.
  db_password_parameter = "/bluegreen-canary/shared/database/password"

  tags = {
    Owner        = local.owner
    Project      = local.project
    Environment  = local.environment
    "aws-apn-id" = local.aws_apn_id
  }
}