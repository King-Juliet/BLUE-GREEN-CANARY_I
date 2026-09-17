variable "blue_alb_dns_name" {
  description = "DNS name of the blue ALB in us-east-1"
  type        = string
}

variable "blue_alb_zone_id" {
  description = "Zone ID of the blue ALB in us-east-1"
  type        = string
}

variable "green_alb_dns_name" {
  description = "DNS name of the green ALB in eu-north-1"
  type        = string
}

variable "green_alb_zone_id" {
  description = "Zone ID of the green ALB in eu-north-1"
  type        = string
}
