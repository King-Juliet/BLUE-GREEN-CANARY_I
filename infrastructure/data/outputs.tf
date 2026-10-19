# The regional stacks read these through terraform_remote_state.

output "vpc_id" {
  value = aws_vpc.data.id
}

output "vpc_cidr" {
  value = aws_vpc.data.cidr_block
}

output "private_route_table_id" {
  value = aws_route_table.private.id
}

output "db_address" {
  value = module.database.db_endpoint
}

output "db_port" {
  value = module.database.db_port
}

output "db_password_parameter" {
  value = local.db_password_parameter
}