variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment label"
  type        = string
}

variable "workload_name" {
  description = "Unique name for this ECS workload"
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
  default     = "placeholder-apn-id"
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "cpu" {
  description = "CPU units for ECS task"
  type        = string
  default     = "256"
}

variable "memory" {
  description = "Memory for ECS task"
  type        = string
  default     = "512"
}

variable "app_port" {
  description = "Application port"
  type        = number
  default     = 8080
}

variable "container_image" {
  description = "Container image reference"
  type        = string
}

variable "container_environment" {
  description = "Container environment variables"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "execution_role_arn" {
  description = "ECS task execution role ARN"
  type        = string
}

variable "task_role_arn" {
  description = "ECS task role ARN"
  type        = string
}

variable "log_group_name" {
  description = "CloudWatch log group name"
  type        = string
}
