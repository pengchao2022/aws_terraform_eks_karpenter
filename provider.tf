# AWS Provider 配置
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = var.tags
  }
}

# Kubernetes provider （保持不变，Helm 会自动读取它）
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

# Helm provider - 简化后的正确写法
provider "helm" {
  debug = true
  
  # 彻底移除了 kubernetes {} 块
  # Helm 会自动寻找并使用上面定义的全局 kubernetes provider 配置
}