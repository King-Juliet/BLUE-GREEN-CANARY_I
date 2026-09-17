# VPC configuration for the regional environment.
resource "aws_vpc" "main" {
  cidr_block           = "10.20.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "${local.project}-vpc"
    Owner       = local.owner
    Project     = local.project
    Environment = local.environment
    "aws-apn-id" = local.aws_apn_id
    Region      = local.aws_region
  }
}

# Internet gateway for public ingress traffic into the regional VPC.
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${local.project}-igw"
    Owner       = local.owner
    Project     = local.project
    Environment = local.environment
    "aws-apn-id" = local.aws_apn_id
    Region      = local.aws_region
  }
}

# Public subnet implementation across the primary availability zones.
module "public_subnets" {
  source = "../modules/subnet"

  project                = local.project
  environment            = local.environment
  owner                  = local.owner
  aws_apn_id             = local.aws_apn_id
  vpc_id                 = aws_vpc.main.id
  name_prefix            = "public"
  subnet_cidrs           = ["10.20.1.0/24", "10.20.2.0/24"]
  availability_zones     = ["eu-north-1a", "eu-north-1b"]
  map_public_ip_on_launch = true
}

# Private subnet implementation across the primary availability zones.
module "private_subnets" {
  source = "../modules/subnet"

  project                = local.project
  environment            = local.environment
  owner                  = local.owner
  aws_apn_id             = local.aws_apn_id
  vpc_id                 = aws_vpc.main.id
  name_prefix            = "private"
  subnet_cidrs           = ["10.20.11.0/24", "10.20.12.0/24"]
  availability_zones     = ["eu-north-1a", "eu-north-1b"]
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
    Name        = "${local.project}-public-route-table"
    Owner       = local.owner
    Project     = local.project
    Environment = local.environment
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
    Name        = "${local.project}-private-route-table"
    Owner       = local.owner
    Project     = local.project
    Environment = local.environment
    "aws-apn-id" = local.aws_apn_id
  }
}

# Association between the private subnets and the private route table.
resource "aws_route_table_association" "private" {
  count          = length(module.private_subnets.subnet_ids)
  subnet_id      = module.private_subnets.subnet_ids[count.index]
  route_table_id = aws_route_table.private.id
}
