# ALB module
# Reusable internet-facing application load balancer.
resource "aws_lb" "main" {
  name               = "${var.project}-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = var.security_group_ids
  subnets            = var.public_subnet_ids

  tags = {
    Owner        = var.owner
    Project      = var.project
    Environment  = var.environment
    "aws-apn-id" = var.aws_apn_id
  }
}

# Configurable target groups and health checks for the regional application services.
resource "aws_lb_target_group" "target_group" {
  for_each = var.target_groups

  name        = each.value.name
  port        = each.value.port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    path                = each.value.health_check_path
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Owner        = var.owner
    Project      = var.project
    Environment  = var.environment
    "aws-apn-id" = var.aws_apn_id
    Region       = var.region
  }
}

# HTTP listener forwarding traffic to the regional frontend service.
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group[var.frontend_target_group].arn
  }
}

# API listener rule forwarding requests to the regional backend service.
resource "aws_lb_listener_rule" "api" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group[var.backend_target_group].arn
  }

  condition {
    path_pattern {
      values = [var.api_path_pattern]
    }
  }
}
