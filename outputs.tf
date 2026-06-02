output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "karpenter_role_arn" {
  description = "Dynamic Karpenter IAM Role ARN for GitHub Actions"
  value       = module.karpenter.karpenter_controller_role_arn
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

# 🌟 修复点：直接引用本地局部变量 local.azs，不再去 module.vpc 里瞎找，避免报错
output "availability_zones" {
  description = "Availability zones used"
  value       = local.azs
}

output "configure_kubectl" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}

output "test_karpenter" {
  description = "Command to test Karpenter auto-scaling"
  value       = "kubectl scale deployment keep-nodes --replicas=5"
}