aws_region       = "us-east-1"
environment      = "dev"
cluster_name     = "allen-eks-karpenter"
cluster_version  = "1.31"
vpc_cidr         = "10.0.0.0/16"
public_subnets   = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
private_subnets  = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
desired_nodes    = 5
tags = {
  Project     = "EKS-Karpenter"
  Environment = "dev"
}
# EKS adds-on version to match 1.31
vpc_cni_version    = "v1.18.3-eksbuild.1"
coredns_version    = "v1.11.3-eksbuild.1"
kube_proxy_version = "v1.31.14-eksbuild.18"