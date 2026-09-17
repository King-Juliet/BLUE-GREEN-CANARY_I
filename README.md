# Cross-Region Blue-Green Canary Deployment Scaffold

This repository demonstrates a GitHub Actions driven AWS ECS Fargate deployment model where the blue service is deployed in the us-east-1 region and the green service is deployed in the eu-north-1 region. The traffic split is handled globally by Route 53 weighted records, which makes the model a true cross-region blue/green canary instead of a one-region ALB weighted target-group pattern.

## Top-level folders

- `applications/` : separate frontend and backend application source and container builds.
- `infrastructure/modules/` : reusable Terraform modules for VPC, subnets, ALB, ECS, ECR, database, SSM, and CloudWatch.
- `infrastructure/us-east-1/` : Terraform files that implement the blue AWS region resources in us-east-1.
- `infrastructure/eu-north-1/` : Terraform files that implement the green AWS region resources in eu-north-1.
- `infrastructure/global/` : Terraform files that model a global routing layer using Route 53 weighted records.
- `.github/workflows/` : GitHub Actions deployment workflow.

## Resource flow

1. Each regional stack creates its VPC, public/private subnets, internet gateway, and route tables.
2. Route 53 points to the regional public ALB, whose default route serves the frontend and whose `/api/*` rule forwards to the backend.
3. The us-east-1 stack runs the blue frontend and blue backend services; the eu-north-1 stack runs the green frontend and green backend services.
4. Each regional stack creates an ECR repository in its own AWS region and stores separate frontend and backend image tags there.
5. Region-specific PostgreSQL RDS instances are placed in private subnets through the database module.
6. Region-specific CloudWatch logs, SNS topics, and alarms are created through the CloudWatch module and regional monitoring files.
7. The global layer uses Route 53 weighted records to split traffic between the blue ALB in us-east-1 and the green ALB in eu-north-1.

## Cross-region canary deployment concept

The GitHub Actions workflow builds separate frontend and backend images and pushes them to the regional ECR repository selected for the release. The first automatic deployment provisions both regional stacks, deploys both blue and green application stacks, and leaves Route 53 at 100% blue and 0% green. It records blue as the active region in SSM. Each later automatic push deploys only the inactive region, canaries traffic toward it at 90/10, and promotes it to 100% after the bake period. If an alarm enters ALARM state, the workflow restores 100% traffic to the previously active region. This alternates naturally: blue -> green, then green -> blue.
