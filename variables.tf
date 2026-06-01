variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "karpenter-demo"
}

variable "cluster_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.29"
}

# 网络配置 - 3个公有子网 + 3个私有子网
variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  description = "Public subnet CIDRs (3 AZs)"
  type        = list(string)
  default = [
    "10.0.1.0/24",
    "10.0.2.0/24",
    "10.0.3.0/24"
  ]
}

variable "private_subnets" {
  description = "Private subnet CIDRs (3 AZs)"
  type        = list(string)
  default = [
    "10.0.10.0/24",
    "10.0.11.0/24",
    "10.0.12.0/24"
  ]
}

variable "tags" {
  description = "Common tags for resources"
  type        = map(string)
  default = {
    Environment = "dev"
    ManagedBy   = "Terraform"
    Project     = "EKS-Karpenter"
  }
}

# Karpenter 配置
variable "karpenter_version" {
  description = "Karpenter Helm chart version"
  type        = string
  default     = "0.37.0"
}

variable "karpenter_instance_families" {
  description = "Allowed EC2 instance families"
  type        = list(string)
  default = ["t2", "t3"]
}

variable "karpenter_instance_sizes" {
  description = "Allowed EC2 instance sizes (免费套餐: micro, small)"
  type        = list(string)
  default     = ["micro", "small"]
}

variable "karpenter_architecture" {
  description = "Instance architecture (amd64 or arm64)"
  type        = string
  default     = "amd64"
}

# 节点配置
variable "desired_nodes" {
  description = "Desired number of nodes to keep running"
  type        = number
  default     = 3
}

# 后端配置变量
variable "state_bucket_name" {
  description = "S3 bucket name for Terraform state"
  type        = string
  default     = "pengchao2022-terraform-state"
}

variable "state_lock_table" {
  description = "DynamoDB table name for state locking"
  type        = string
  default     = "terraform-state-lock"
}