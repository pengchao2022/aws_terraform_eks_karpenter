# 获取 AWS 可用区（前3个）
data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 3)
}

# 获取当前 AWS 账号 ID
data "aws_caller_identity" "current" {}

# 获取当前 AWS 区域
data "aws_region" "current" {}

# 创建 VPC 模块
module "vpc" {
  source = "./modules/vpc"

  environment         = var.environment
  cluster_name        = var.cluster_name
  vpc_cidr           = var.vpc_cidr
  public_subnets     = var.public_subnets
  private_subnets    = var.private_subnets
  availability_zones = local.azs

  tags = var.tags
}

# 创建 EKS 模块
module "eks" {
  source = "./modules/eks"

  environment         = var.environment
  cluster_name        = var.cluster_name
  cluster_version     = var.cluster_version
  vpc_id              = module.vpc.vpc_id
  private_subnet_ids  = module.vpc.private_subnet_ids
  public_subnet_ids   = module.vpc.public_subnet_ids
  
  tags = var.tags
}

# 创建 Karpenter 模块
module "karpenter" {
  source = "./modules/karpenter"
  cluster_name                = module.eks.cluster_name
  cluster_endpoint           = module.eks.cluster_endpoint
  cluster_certificate_authority = module.eks.cluster_certificate_authority
  openid_connect_provider_arn  = module.eks.oidc_provider_arn
  openid_connect_provider_url   = module.eks.oidc_provider_url
  
  namespace           = "karpenter"
  kubernetes_version  = var.cluster_version
  desired_nodes       = var.desired_nodes
  instance_families   = var.karpenter_instance_families
  instance_sizes      = var.karpenter_instance_sizes
  architecture        = var.karpenter_architecture
  karpenter_version   = var.karpenter_version
  
  tags = var.tags
}