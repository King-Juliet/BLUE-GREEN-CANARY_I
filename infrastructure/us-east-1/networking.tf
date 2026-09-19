# VPC configuration for the regional environment.
resource "aws_vpc" "main" {
  cidr_block           = "10.10.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name         = "${local.project}-vpc"
    Owner        = local.owner
    Project      = local.project
    Environment  = local.environment
    "aws-apn-id" = local.aws_apn_id
    Region       = local.aws_region
  }
}

# Internet gateway for public ingress traffic into the regional VPC.
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name         = "${local.project}-igw"
    Owner        = local.owner
    Project      = local.project
    Environment  = local.environment
    "aws-apn-id" = local.aws_apn_id
    Region       = local.aws_region
  }
}

# Public subnet implementation across the primary availability zones.
module "public_subnets" {
  source = "../modules/subnet"

  project                 = local.project
  environment             = local.environment
  owner                   = local.owner
  aws_apn_id              = local.aws_apn_id
  vpc_id                  = aws_vpc.main.id
  name_prefix             = "public"
  subnet_cidrs            = ["10.10.1.0/24", "10.10.2.0/24"]
  availability_zones      = ["us-east-1a", "us-east-1b"]
  map_public_ip_on_launch = true
}

# Private subnet implementation across the primary availability zones.
module "private_subnets" {
  source = "../modules/subnet"

  project                 = local.project
  environment             = local.environment
  owner                   = local.owner
  aws_apn_id              = local.aws_apn_id
  vpc_id                  = aws_vpc.main.id
  name_prefix             = "private"
  subnet_cidrs            = ["10.10.11.0/24", "10.10.12.0/24"]
  availability_zones      = ["us-east-1a", "us-east-1b"]
  map_public_ip_on_launch = false
}

# Public route table controlling outbound internet access for public subnets.
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name         = "${local.project}-public-route-table"
    Owner        = local.owner
    Project      = local.project
    Environment  = local.environment
    "aws-apn-id" = local.aws_apn_id
  }
}

# Association between the public subnets and the public route table.
resource "aws_route_table_association" "public" {
  count          = length(module.public_subnets.subnet_ids)
  subnet_id      = module.public_subnets.subnet_ids[count.index]
  route_table_id = aws_route_table.public.id
}

# Private route table for internal-only routing without a NAT gateway.
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name         = "${local.project}-private-route-table"
    Owner        = local.owner
    Project      = local.project
    Environment  = local.environment
    "aws-apn-id" = local.aws_apn_id
  }
}

# Association between the private subnets and the private route table.
resource "aws_route_table_association" "private" {
  count          = length(module.private_subnets.subnet_ids)
  subnet_id      = module.private_subnets.subnet_ids[count.index]
  route_table_id = aws_route_table.private.id
}


# vpc endpoint configurations
# Security group for VPC endpoints — allows the ECS tasks to reach them over HTTPS.
resource "aws_security_group" "vpc_endpoints" {
  name        = "${local.project}-${local.environment}-vpce-sg"
  description = "Security group for VPC interface endpoints"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name         = "${local.project}-vpce-sg"
    Owner        = local.owner
    Project      = local.project
    Environment  = local.environment
    "aws-apn-id" = local.aws_apn_id
  }
}

resource "aws_vpc_security_group_ingress_rule" "vpce_from_ecs" {
  security_group_id            = aws_security_group.vpc_endpoints.id
  referenced_security_group_id = aws_security_group.ecs.id
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
}

# Interface endpoints — ECR API, ECR image layer pulls, CloudWatch Logs.
resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${local.aws_region}.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.private_subnets.subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name = "${local.project}-ecr-api-endpoint"
  }
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${local.aws_region}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.private_subnets.subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name = "${local.project}-ecr-dkr-endpoint"
  }
}

resource "aws_vpc_endpoint" "logs" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${local.aws_region}.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.private_subnets.subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name = "${local.project}-logs-endpoint"
  }
}

# Gateway endpoint — S3, where ECR actually stores image layers. Free, route-table based, not SG based.
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${local.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id]

  tags = {
    Name = "${local.project}-s3-endpoint"
  }
}

resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${local.aws_region}.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.private_subnets.subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name = "${local.project}-ssm-endpoint"
  }
}