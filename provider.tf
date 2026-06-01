# AWS Provider 配置（保持不变）
provider "aws" {
  region = var.aws_region
  default_tags {
    tags = var.tags
  }
}

# Kubernetes provider （保持不变，这是全局凭据的源头）
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

# Helm provider - 终极精简版
provider "helm" {
  debug = true
  
  # 里面什么都不写！
  # 只要上面的 provider "kubernetes" 已经就绪，Helm 会自动读取全局配置。
}