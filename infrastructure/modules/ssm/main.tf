# SSM module
# Secure database password stored in AWS Systems Manager Parameter Store.
resource "aws_ssm_parameter" "ssm_parameter" {
  name        = var.parameter_name
  description = var.description
  type        = "SecureString"
  value       = var.password

  tags = {
    Name         = var.project
    Owner        = var.owner
    Project      = var.project
    Environment  = var.environment
    "aws-apn-id" = var.aws_apn_id
  }
}
