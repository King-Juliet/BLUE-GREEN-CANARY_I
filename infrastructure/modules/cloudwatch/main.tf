# CloudWatch module
# Application log group for the regional environment.
resource "aws_cloudwatch_log_group" "cloudwatch_log_group" {
  name = var.log_group_name

  tags = {
    Owner       = var.owner
    Project     = var.project
    Environment = var.environment
    "aws-apn-id" = var.aws_apn_id
  }
}

# ALB 5xx alarm used to support canary rollback decisions.
resource "aws_cloudwatch_metric_alarm" "cloudwatch_alarm" {
  alarm_name          = var.alarm_name
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic          = "Sum"
  threshold           = var.alb_5xx_threshold
  alarm_description   = "ALB 5xx alarm for canary rollback decisions"
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = var.alb_arn
  }

  alarm_actions = [var.sns_topic_arn]
}
