# output "parameter_arn" {
#   value = aws_ssm_parameter.db_password.arn
# }

# output "parameter_name" {
#   value = aws_ssm_parameter.db_password.name
# }

output "parameter_arn" {
  value = aws_ssm_parameter.ssm_parameter.arn
}

output "parameter_name" {
  value = aws_ssm_parameter.ssm_parameter.name
}