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

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_cidrs" {
  description = "CIDR blocks for the subnet set"
  type        = list(string)
}

variable "availability_zones" {
  description = "Availability zones for the subnet set"
  type        = list(string)
}

variable "name_prefix" {
  description = "Prefix used in subnet names"
  type        = string
  default     = "subnet"
}

variable "map_public_ip_on_launch" {
  description = "Whether instances launched in the subnet should receive a public IP"
  type        = bool
  default     = false
}
