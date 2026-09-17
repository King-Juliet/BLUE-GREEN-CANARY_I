output "db_instance_id" {
  value = aws_db_instance.database.id
}

output "db_endpoint" {
  value = aws_db_instance.database.address
}

output "db_port" {
  value = aws_db_instance.database.port
}
