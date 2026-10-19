# The database no longer lives in this region. It runs in the shared data stack (infrastructure/data),
# which is created first by the pipeline and never destroyed. This reads its outputs.
data "terraform_remote_state" "data" {
  backend = "s3"

  config = {
    bucket = "juliet-blue-green-canary-tfstate"
    key    = "data/terraform.tfstate"
    region = "us-east-1"
  }
}