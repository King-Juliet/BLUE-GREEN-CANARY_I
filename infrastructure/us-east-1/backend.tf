terraform {
  backend "s3" {
    bucket       = "juliet-blue-green-canary-tfstate"
    key          = "blue/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
    encrypt      = true
  }
}

 
