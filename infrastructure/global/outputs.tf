output "route53_zone_id" {
  value = aws_route53_zone.main.zone_id
}

output "route53_record_name" {
  value = aws_route53_record.blue.name
}
