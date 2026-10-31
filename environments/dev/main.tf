/*
compute and database modules rely on module.networking and module.compute
*/


terraform {
  required_version = ">= 1.10.0"

  backend "s3" {
    bucket       = "secure-threetier-tfstate-123456789" # Ensure this is your actual bucket name
    key          = "dev/network/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = "us-east-1"
}

module "networking" {
  source = "../../modules/networking"

  environment = "dev"
  vpc_cidr    = "10.0.0.0/16"
  azs         = ["us-east-1a", "us-east-1b"]
  single_nat  = true
}

module "compute" {
  source = "../../modules/compute"

  environment            = "dev"
  vpc_id                 = module.networking.vpc_id
  public_subnet_ids      = module.networking.public_subnet_ids
  private_app_subnet_ids = module.networking.private_app_subnet_ids
  instance_type          = "t3.micro"
}

module "database" {
  source = "../../modules/database"

  environment             = "dev"
  vpc_id                  = module.networking.vpc_id
  private_data_subnet_ids = module.networking.private_data_subnet_ids
  app_security_group_id   = module.compute.app_security_group_id
  multi_az                = false # Cost saving for dev
}

module "security" {
  source = "../../modules/security"

  environment = "dev"
  alb_arn     = module.compute.alb_arn
}

module "s3_governance" {
  source = "../../modules/s3_governance"

  environment = "dev"
}

module "security_posture" {
  source = "../../modules/security_posture"

  environment = "dev"
}

module "observability" {
  source = "../../modules/observability"

  environment     = "dev"
  sns_alert_email = "prathameshwadile0@gmail.com" # <-- Change this to your actual email address
  asg_name        = module.compute.asg_name
  alb_arn_suffix  = module.compute.alb_arn_suffix
}

module "cicd" {
  source = "../../modules/cicd"

  environment      = "dev"
  github_repo_name = "prathamesh-wadile/secure-threetier-platform" # <-- Change this
}

