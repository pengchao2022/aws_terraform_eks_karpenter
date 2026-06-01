# AWS 配置
aws_region      = "us-east-1"
environment     = "dev"
cluster_name    = "allen-eks-karpenter"
cluster_version = "1.29"


vpc_cidr = "10.0.0.0/16"

public_subnets = [
  "10.0.1.0/24",  
  "10.0.2.0/24",  
  "10.0.3.0/24"  
]

private_subnets = [
  "10.0.10.0/24", 
  "10.0.11.0/24", 
  "10.0.12.0/24"  
]

# 标签
tags = {
  Environment = "dev"
  ManagedBy   = "Terraform"
  Project     = "EKS-Karpenter"
}

# Karpenter 配置
karpenter_version           = "0.37.0"
karpenter_instance_families = ["t2", "t3"]  # 免费套餐系列
karpenter_instance_sizes    = ["micro", "small"]  # 免费套餐大小
karpenter_architecture      = "amd64"

# 节点配置
desired_nodes = 3