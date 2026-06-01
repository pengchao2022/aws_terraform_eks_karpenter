terraform {
  backend "s3" {
    bucket         = "pengchao2022-terraform-state"
    key            = "eks-karpenter/terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}