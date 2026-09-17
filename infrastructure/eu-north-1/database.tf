# Random database password generated for this regional environment.
resource "random_password" "db_password" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}:?"
}

# SSM Parameter Store entry containing the generated database password.
module "ssm_db_password" {
  source = "../modules/ssm"

  project        = local.project
  environment    = local.environment
  owner          = local.owner
  aws_apn_id     = local.aws_apn_id
  parameter_name = "/bluegreen-canary/${local.environment}/${local.aws_region}/database/password"
  description    = "Secure database password for ${local.project} in ${local.aws_region}"
  password       = random_password.db_password.result
}

# RDS database and subnet group configuration for this region.
module "database" {
  source = "../modules/database"

  project             = local.project
  environment         = local.environment
  owner               = local.owner
  aws_apn_id          = local.aws_apn_id
  private_subnet_ids = module.private_subnets.subnet_ids
  security_group_ids = [aws_security_group.rds.id]
  db_username        = "appuser"
  db_password        = random_password.db_password.result
  multi_az           = false
}
