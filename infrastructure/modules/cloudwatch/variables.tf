variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment label"
  type        = string
}

variable "owner" {
  description = "Resource owner"
  type        = string
  default     = "platform-team"
}

variable "aws_apn_id" {
  description = "AWS APN identifier"
  type        = string
  default     = "65jiyh5muw5om1whvryxkbpyd"
}

variable "alb_arn" {
  description = "ALB ARN used for alarm dimensions"
  type        = string
}

variable "log_group_name" {
  description = "CloudWatch log group name"
  type        = string
}

variable "alarm_name" {
  description = "CloudWatch metric alarm name"
  type        = string
}

variable "sns_topic_arn" {
  description = "SNS topic ARN receiving alarm notifications"
  type        = string
}

variable "alb_5xx_threshold" {
  description = "ALB target 5xx threshold before alarm"
  type        = number
  default     = 5
}
