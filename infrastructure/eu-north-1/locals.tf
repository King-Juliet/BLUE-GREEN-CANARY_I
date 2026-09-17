locals {
  project           = "bluegreen-canary-green"
  environment       = "green"
  owner             = "platform-team"
  aws_apn_id        = "65jiyh5muw5om1whvryxkbpyd"
  aws_region        = "eu-north-1"
  app_port          = 8080
  health_check_path = "/health"
  tags = {
    Owner        = local.owner
    Project      = "bluegreen-canary"
    Environment  = local.environment
    "aws-apn-id" = local.aws_apn_id
    Region       = local.aws_region
  }
}
