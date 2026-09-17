# Security group allowing public HTTP traffic to the application load balancer.
resource "aws_security_group" "alb" {
  name        = "${local.project}-${local.environment}-alb-sg"
  description = "Security group for the application load balancer"
  vpc_id      = aws_vpc.main.id
}

# Public HTTP ingress rule for the application load balancer.
resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

# Outbound access rule for the application load balancer.
resource "aws_vpc_security_group_egress_rule" "alb_all" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# Security group allowing application traffic from the load balancer to ECS tasks.
resource "aws_security_group" "ecs" {
  name        = "${local.project}-${local.environment}-ecs-sg"
  description = "Security group for ECS tasks"
  vpc_id      = aws_vpc.main.id
}

# Application ingress rule from the ALB to ECS tasks.
resource "aws_vpc_security_group_ingress_rule" "ecs_from_alb" {
  security_group_id            = aws_security_group.ecs.id
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = local.app_port
  ip_protocol                  = "tcp"
  to_port                      = local.app_port
}

# Outbound access rule for ECS tasks.
resource "aws_vpc_security_group_egress_rule" "ecs_all" {
  security_group_id = aws_security_group.ecs.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# Application load balancer and target group configuration for this region.
module "alb" {
  source = "../modules/alb"

  project            = local.project
  environment        = local.environment
  owner              = local.owner
  aws_apn_id         = local.aws_apn_id
  region             = local.aws_region
  vpc_id             = aws_vpc.main.id
  public_subnet_ids  = module.public_subnets.subnet_ids
  security_group_ids = [aws_security_group.alb.id]
  target_groups = {
    frontend = {
      name              = "${local.project}-${local.environment}-frontend-tg"
      port              = local.app_port
      health_check_path = local.health_check_path
    }
    backend = {
      name              = "${local.project}-${local.environment}-backend-tg"
      port              = local.app_port
      health_check_path = local.health_check_path
    }
  }
  frontend_target_group = "frontend"
  backend_target_group  = "backend"
}

# Security group allowing PostgreSQL traffic from ECS tasks to the database.
resource "aws_security_group" "rds" {
  name        = "${local.project}-${local.environment}-rds-sg"
  description = "Security group for RDS PostgreSQL"
  vpc_id      = aws_vpc.main.id
}

# PostgreSQL ingress rule from ECS tasks to the database.
resource "aws_vpc_security_group_ingress_rule" "rds_from_ecs" {
  security_group_id            = aws_security_group.rds.id
  referenced_security_group_id = aws_security_group.ecs.id
  from_port                    = 5432
  ip_protocol                  = "tcp"
  to_port                      = 5432
}

# Outbound access rule for the database security group.
resource "aws_vpc_security_group_egress_rule" "rds_all" {
  security_group_id = aws_security_group.rds.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
