# CloudWatch log group and alarm configuration for this regional environment.
# SNS topic for regional deployment and rollback notifications.
resource "aws_sns_topic" "deploy_notifications" {
  name = "${local.project}-${local.environment}-deploy-notifications"

  tags = local.tags
}

# Reusable CloudWatch log group and ALB alarm configuration.
module "cloudwatch" {
  source = "../modules/cloudwatch"

  project            = local.project
  environment        = local.environment
  owner              = local.owner
  aws_apn_id         = local.aws_apn_id
  alb_arn            = module.alb.alb_arn
  log_group_name     = "/ecs/${local.project}/${local.environment}"
  alarm_name         = "${local.project}-${local.environment}-alb-5xx"
  sns_topic_arn      = aws_sns_topic.deploy_notifications.arn
  alb_5xx_threshold = 5
}
