# Regional ECR repository for images deployed in eu-north-1.
module "ecr" {
  source = "../modules/ecr"

  project         = local.project
  environment     = local.environment
  owner           = local.owner
  aws_apn_id      = local.aws_apn_id
  region          = local.aws_region
  repository_name = local.project
}
