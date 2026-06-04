terraform {
  required_version = ">= 1.5.0"  # this is for lowest version of terraform to run this project 
  required_providers {
    aws = {
      source  = "hashicorp/aws" # this is to tell terraform to go to hashicorp terraform registry then download aws plugin
      version = "~> 5.80"       # the aws plugin version in hashicorp should greater than 5.80
    }
  }
}

provider "aws" {
  region = var.aws_region # here declare the target region 
                          # here requires aws credentials
                          # the credential can be aws configure or for github secrets OIDC AWS_IAM_Role
                          # OIDC is for OpenID Connect
}