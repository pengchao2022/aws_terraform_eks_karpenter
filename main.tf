data "aws_availability_zones" "available" { state = "available" }
locals { azs = slice(data.aws_availability_zones.available.names, 0, 3) }

# 1. 基建层：VPC 网络
module "vpc" {
  source              = "./modules/vpc"
  environment         = var.environment
  cluster_name        = var.cluster_name
  vpc_cidr            = var.vpc_cidr
  public_subnets      = var.public_subnets
  private_subnets     = var.private_subnets
  availability_zones  = local.azs
  tags                = var.tags
}

# 2. 核心层：EKS 集群底座 (1.30)
module "eks" {
  source              = "./modules/eks"
  environment         = var.environment
  cluster_name        = var.cluster_name
  cluster_version     = var.cluster_version
  vpc_id              = module.vpc.vpc_id
  private_subnet_ids  = module.vpc.private_subnet_ids
  public_subnet_ids   = module.vpc.public_subnet_ids
  tags                = var.tags
}

# 3. 权限层：Karpenter 专属 AWS IAM 角色与策略
module "karpenter" {
  source                        = "./modules/karpenter"
  cluster_name                  = module.eks.cluster_name
  # 🌟 修复点：必须在这里把 EKS 模块产生的端点塞给 Karpenter 模块，两端才能彻底合龙！
  cluster_endpoint              = module.eks.cluster_endpoint 
  openid_connect_provider_arn    = module.eks.oidc_provider_arn
  openid_connect_provider_url    = module.eks.oidc_provider_url
  namespace                     = "karpenter"
  tags                          = var.tags

  depends_on = [module.eks]
}