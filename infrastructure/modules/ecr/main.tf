# ECR module
# Regional container image repository for the application deployment.
resource "aws_ecr_repository" "repository" {
  name                 = var.repository_name
  image_tag_mutability = var.image_tag_mutability

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Owner       = var.owner
    Project     = var.project
    Environment = var.environment
    "aws-apn-id" = var.aws_apn_id
    Region      = var.region
  }
}

# Retain recent images while removing untagged layers to control registry storage.
resource "aws_ecr_lifecycle_policy" "repository" {
  repository = aws_ecr_repository.repository.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Remove untagged images after fourteen days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 14
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
