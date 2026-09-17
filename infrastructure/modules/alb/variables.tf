variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
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

variable "region" {
  description = "AWS region for resource tags"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for target groups"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for the load balancer"
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security group IDs for the load balancer"
  type        = list(string)
}

variable "target_groups" {
  description = "Target groups and health-check settings for the regional services"
  type = map(object({
    name              = string
    port              = number
    health_check_path = string
  }))
}

variable "frontend_target_group" {
  description = "Key of the regional frontend target group"
  type        = string
}

variable "backend_target_group" {
  description = "Key of the regional backend target group"
  type        = string
}

variable "api_path_pattern" {
  description = "Listener path pattern for backend API requests"
  type        = string
  default     = "/api/*"
}

