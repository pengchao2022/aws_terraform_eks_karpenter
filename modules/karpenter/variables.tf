variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "cluster_endpoint" {
  description = "EKS cluster endpoint"
  type        = string
}

variable "cluster_certificate_authority" {
  description = "EKS cluster CA certificate"
  type        = string
}

variable "openid_connect_provider_arn" {
  description = "OIDC Provider ARN"
  type        = string
}

variable "openid_connect_provider_url" {
  description = "OIDC Provider URL"
  type        = string
}

variable "namespace" {
  description = "Karpenter namespace"
  type        = string
  default     = "karpenter"
}

variable "karpenter_version" {
  description = "Karpenter Helm chart version"
  type        = string
  default     = "0.37.0"
}

variable "instance_families" {
  description = "Allowed EC2 instance families"
  type        = list(string)
  default     = ["t2", "t3"]
}

variable "instance_sizes" {
  description = "Allowed EC2 instance sizes (免费套餐: micro, small)"
  type        = list(string)
  default     = ["micro", "small"]
}

variable "architecture" {
  description = "Instance architecture"
  type        = string
  default     = "amd64"
}

variable "kubernetes_version" {
  description = "Kubernetes version for AMI selection"
  type        = string
  default     = "1.29"
}

variable "desired_nodes" {
  description = "Desired number of nodes to keep running"
  type        = number
  default     = 3
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}