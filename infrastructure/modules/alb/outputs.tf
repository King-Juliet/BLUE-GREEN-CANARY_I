output "alb_dns_name" {
  value = aws_lb.main.dns_name
}

output "alb_zone_id" {
  value = aws_lb.main.zone_id
}

output "alb_arn" {
  value = aws_lb.main.arn
}

output "target_group_arns" {
  value = {
    for name, target_group in aws_lb_target_group.target_group : name => target_group.arn
  }
}

output "listener_arn" {
  value = aws_lb_listener.http.arn
}
