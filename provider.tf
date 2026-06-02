terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.80" # 强制使用新版，修复 EKS API 更新 Bug
    }
  }
}

provider "aws" {
  region = var.aws_region
}