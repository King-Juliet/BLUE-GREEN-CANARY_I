locals {
  project           = "bluegreen-canary-blue"
  environment       = "blue"
  owner             = "platform-team"
  aws_apn_id        = "placeholder-apn-id"
  aws_region        = "us-east-1"
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
