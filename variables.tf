variable "aws_region" {
  type        = string
  description = "The AWS region where all resources will be deployed."
  default     = "us-east-1"
}

variable "environment" {
  type        = string
  description = "The deployment environment name (e.g., dev, staging, prod)."
  default     = "dev"
}

variable "cluster_name" {
  type        = string
  description = "The name of the EKS cluster."
  default     = "allen-eks-karpenter"
}

variable "cluster_version" {
  type        = string
  description = "The Kubernetes minor version to use for the EKS cluster."
  default     = "1.30"
}

variable "vpc_cidr" {
  type        = string
  description = "The master CIDR block for the VPC network."
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  type        = list(string)
  description = "A list of CIDR blocks for the 3 public subnets."
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnets" {
  type        = list(string)
  description = "A list of CIDR blocks for the 3 private subnets."
  default     = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
}

variable "desired_nodes" {
  type        = number
  description = "The initial or target number of worker nodes managed by the cluster deployment."
  default     = 3
}

variable "tags" {
  type        = map(string)
  description = "A standard map of tags to apply to all taggable AWS resources."
  default = {
    Project     = "EKS-Karpenter"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

variable "vpc_cni_version" {
  type        = string
  description = "The specific version of the AWS VPC CNI add-on compatible with the target Kubernetes version."
}

variable "coredns_version" {
  type        = string
  description = "The specific version of the CoreDNS add-on compatible with the target Kubernetes version."
}

variable "kube_proxy_version" {
  type        = string
  description = "The specific version of the Kube-Proxy add-on compatible with the target Kubernetes version."
}