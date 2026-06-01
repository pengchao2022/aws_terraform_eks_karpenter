# AWS Provider 配置（保持不变）
provider "aws" {
  region = var.aws_region
  default_tags {
    tags = var.tags
  }
}

# 1. 核心：在这里完整配置 Kubernetes 凭据
provider "kubernetes" {
  host                   = module.vpc_eks.cluster_endpoint # 请根据你实际的 module 命名修改，例如 module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.vpc_eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

# 2. 核心修复：Helm 块里保持绝对干净，它会自动继承上面 kubernetes 的 exec 认证
provider "helm" {
  # 🛑 删掉里面原本报错的 kubernetes { ... } 整个子块
  # 只留这个壳，或者留一行 debug 即可
  debug = true
}