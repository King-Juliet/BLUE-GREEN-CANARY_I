# IAM trust policy allowing ECS tasks to assume their execution and task roles.
data "aws_iam_policy_document" "ecs_task_execution" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# IAM role used by ECS to pull images and publish task logs.
resource "aws_iam_role" "ecs_execution" {
  name               = "${local.project}-${local.environment}-ecs-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_execution.json
}

# AWS-managed execution policy attachment for the ECS execution role.
resource "aws_iam_role_policy_attachment" "ecs_execution_ecr" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Permission for the backend task to read its regional database password.
resource "aws_iam_role_policy" "ecs_task_ssm" {
  name = "${local.project}-${local.environment}-ecs-ssm-read"
  role = aws_iam_role.ecs_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["ssm:GetParameter"]
      Resource = "arn:aws:ssm:${local.aws_region}:*:parameter/bluegreen-canary/${local.environment}/${local.aws_region}/database/password"
    }]
  })
}

# IAM role assumed by the running application containers.
resource "aws_iam_role" "ecs_task" {
  name               = "${local.project}-${local.environment}-ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_execution.json
}

# Blue frontend ECS cluster and task definition for this region.
module "frontend_ecs" {
  source = "../modules/ecs"

  project            = local.project
  environment        = local.environment
  workload_name      = "${local.project}-${local.environment}-frontend"
  owner              = local.owner
  aws_apn_id         = local.aws_apn_id
  region             = local.aws_region
  app_port           = local.app_port
  container_image    = "${module.ecr.repository_url}:frontend-${local.environment}"
  execution_role_arn = aws_iam_role.ecs_execution.arn
  task_role_arn      = aws_iam_role.ecs_task.arn
  log_group_name     = module.cloudwatch.log_group_name
}


# Blue backend ECS cluster and task definition for this region.
module "backend_ecs" {
  source = "../modules/ecs"

  project            = local.project
  environment        = local.environment
  workload_name      = "${local.project}-${local.environment}-backend"
  owner              = local.owner
  aws_apn_id         = local.aws_apn_id
  region             = local.aws_region
  app_port           = local.app_port
  container_image    = "${module.ecr.repository_url}:backend-${local.environment}"
  execution_role_arn = aws_iam_role.ecs_execution.arn
  task_role_arn      = aws_iam_role.ecs_task.arn
  log_group_name     = module.cloudwatch.log_group_name
  container_environment = [
    { name = "PORT", value = tostring(local.app_port) },
    { name = "AWS_REGION", value = local.aws_region },
    { name = "DB_HOST", value = module.database.db_endpoint },
    { name = "DB_PORT", value = tostring(module.database.db_port) },
    { name = "DB_USER", value = "appuser" },
    { name = "DB_NAME", value = "appdb" },
    { name = "DB_CREDENTIALS_SSM_NAME", value = "/bluegreen-canary/${local.environment}/${local.aws_region}/database/password" }
  ]
}


# Blue frontend ECS service receiving public web traffic in this region.
resource "aws_ecs_service" "frontend" {
  name            = "${local.project}-${local.environment}-frontend-service"
  cluster         = module.frontend_ecs.cluster_id
  task_definition = module.frontend_ecs.task_definition_arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = module.private_subnets.subnet_ids
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = module.alb.target_group_arns["frontend"]
    container_name   = "app"
    container_port   = local.app_port
  }
}

# Blue backend ECS service receiving /api/* traffic from the ALB.
resource "aws_ecs_service" "backend" {
  name            = "${local.project}-${local.environment}-backend-service"
  cluster         = module.backend_ecs.cluster_id
  task_definition = module.backend_ecs.task_definition_arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = module.private_subnets.subnet_ids
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = module.alb.target_group_arns["backend"]
    container_name   = "app"
    container_port   = local.app_port
  }
}

