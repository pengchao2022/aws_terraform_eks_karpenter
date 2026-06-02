data "aws_availability_zones" "available" { state = "available" }
locals { azs = slice(data.aws_availability_zones.available.names, 0, 3) }

# Infra VPC creation
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

# EKS creation
module "eks" {
  source              = "./modules/eks"
  environment         = var.environment
  cluster_name        = var.cluster_name
  cluster_version     = var.cluster_version
  vpc_id              = module.vpc.vpc_id
  private_subnet_ids  = module.vpc.private_subnet_ids
  public_subnet_ids   = module.vpc.public_subnet_ids
  tags                = var.tags
  desired_nodes       = var.desired_nodes
  vpc_cni_version    = var.vpc_cni_version
  coredns_version    = var.coredns_version
  kube_proxy_version = var.kube_proxy_version
}

# permission Karpenter-Specific AWS IAM Roles and Policies
module "karpenter" {
  source                        = "./modules/karpenter"
  cluster_name                  = module.eks.cluster_name
  cluster_endpoint              = module.eks.cluster_endpoint 
  openid_connect_provider_arn    = module.eks.oidc_provider_arn
  openid_connect_provider_url    = module.eks.oidc_provider_url
  namespace                     = "karpenter"
  tags                          = var.tags

  depends_on = [module.eks]
}