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

variable "parameter_name" {
  description = "SSM parameter name for database credential"
  type        = string
}

variable "description" {
  description = "Description for the SSM database credential parameter"
  type        = string
}

variable "password" {
  description = "Password value stored in the SSM parameter"
  type        = string
  sensitive   = true
}
