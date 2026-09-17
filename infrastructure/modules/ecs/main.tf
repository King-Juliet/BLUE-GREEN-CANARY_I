# ECS module
# Reusable ECS cluster for the regional application workload.
resource "aws_ecs_cluster" "main" {
  name = "${var.workload_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name        = "${var.workload_name}-cluster"
    Owner       = var.owner
    Project     = var.project
    Environment = var.environment
    "aws-apn-id" = var.aws_apn_id
  }
}
# Shared Fargate task definition for regional ECS services.
resource "aws_ecs_task_definition" "app" {
  family                   = "${var.workload_name}-task"
  cpu                      = var.cpu
  memory                   = var.memory
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([
    {
      name      = "app"
      image     = var.container_image
      essential = true
      portMappings = [
        {
          containerPort = var.app_port
          hostPort      = var.app_port
          protocol      = "tcp"
        }
      ]
      environment = var.container_environment
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = var.log_group_name
          awslogs-region        = var.region
          awslogs-stream-prefix = var.project
        }
      }
    }
  ])

  tags = {
    Name        = "${var.workload_name}-task"
    Owner       = var.owner
    Project     = var.project
    Environment = var.environment
    "aws-apn-id" = var.aws_apn_id
  }
}
