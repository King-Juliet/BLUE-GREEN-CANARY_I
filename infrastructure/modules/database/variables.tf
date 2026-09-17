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

variable "private_subnet_ids" {
  description = "Private subnet IDs for DB subnet group"
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security groups for RDS"
  type        = list(string)
}

variable "allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 20
}

variable "engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "15.4"
}

variable "instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Database username"
  type        = string
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "db_port" {
  description = "Database port"
  type        = number
  default     = 5432
}

variable "multi_az" {
  description = "RDS multi-AZ deployment"
  type        = bool
  default     = false
}
