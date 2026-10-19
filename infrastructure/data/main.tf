# Shared data stack: the ONE database used by whichever region(s) are running.
#
# Blue (us-east-1) and green (eu-north-1) are stateless and can be created or destroyed on every
# release. This stack is never destroyed by the pipeline, so the data survives. Each region reaches
# the database over a VPC peering connection that the REGION's own stack creates (see peering.tf there).

# Dedicated VPC for the database. No internet gateway and no NAT: it is private on purpose.
resource "aws_vpc" "data" {
  cidr_block           = local.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.tags, {
    Name   = "${local.project}-${local.environment}-vpc"
    Region = local.aws_region
  })
}

# Private subnets in two AZs (an RDS subnet group needs at least two).
module "private_subnets" {
  source = "../modules/subnet"

  project                 = local.project
  environment             = local.environment
  owner                   = local.owner
  aws_apn_id              = local.aws_apn_id
  vpc_id                  = aws_vpc.data.id
  name_prefix             = "data-private"
  subnet_cidrs            = ["10.30.11.0/24", "10.30.12.0/24"]
  availability_zones      = ["us-east-1a", "us-east-1b"]
  map_public_ip_on_launch = false
}

# Route table for the database subnets. Each region's stack adds a route back to its own VPC here.
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.data.id

  tags = merge(local.tags, {
    Name = "${local.project}-${local.environment}-private-route-table"
  })
}

resource "aws_route_table_association" "private" {
  count          = length(module.private_subnets.subnet_ids)
  subnet_id      = module.private_subnets.subnet_ids[count.index]
  route_table_id = aws_route_table.private.id
}

# Security group for the database: PostgreSQL from the two regional VPC ranges only.
resource "aws_security_group" "rds" {
  name        = "${local.project}-${local.environment}-rds-sg"
  description = "Security group for the shared RDS PostgreSQL"
  vpc_id      = aws_vpc.data.id

  tags = merge(local.tags, {
    Name = "${local.project}-${local.environment}-rds-sg"
  })
}

resource "aws_vpc_security_group_ingress_rule" "rds_from_blue" {
  security_group_id = aws_security_group.rds.id
  cidr_ipv4         = local.blue_vpc_cidr
  from_port         = 5432
  ip_protocol       = "tcp"
  to_port           = 5432
  description       = "PostgreSQL from the blue region VPC"
}

resource "aws_vpc_security_group_ingress_rule" "rds_from_green" {
  security_group_id = aws_security_group.rds.id
  cidr_ipv4         = local.green_vpc_cidr
  from_port         = 5432
  ip_protocol       = "tcp"
  to_port           = 5432
  description       = "PostgreSQL from the green region VPC"
}

resource "aws_vpc_security_group_egress_rule" "rds_all" {
  security_group_id = aws_security_group.rds.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# Random database password, generated once and kept in this stack's state.
resource "random_password" "db_password" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}:?"
}

# The password is stored in SSM in BOTH regions under the same name.
module "ssm_db_password_blue" {
  source = "../modules/ssm"

  project        = local.project
  environment    = local.environment
  owner          = local.owner
  aws_apn_id     = local.aws_apn_id
  parameter_name = local.db_password_parameter
  description    = "Shared database password for ${local.project} (us-east-1 copy)"
  password       = random_password.db_password.result
}

module "ssm_db_password_green" {
  source = "../modules/ssm"

  providers = {
    aws = aws.eu_north_1
  }

  project        = local.project
  environment    = local.environment
  owner          = local.owner
  aws_apn_id     = local.aws_apn_id
  parameter_name = local.db_password_parameter
  description    = "Shared database password for ${local.project} (eu-north-1 copy)"
  password       = random_password.db_password.result
}

# The shared RDS PostgreSQL database.
module "database" {
  source = "../modules/database"

  project            = local.project
  environment        = local.environment
  owner              = local.owner
  aws_apn_id         = local.aws_apn_id
  private_subnet_ids = module.private_subnets.subnet_ids
  security_group_ids = [aws_security_group.rds.id]
  db_username        = "appuser"
  db_password        = random_password.db_password.result
  multi_az           = false
}