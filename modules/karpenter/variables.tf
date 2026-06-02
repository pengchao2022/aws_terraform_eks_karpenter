variable "cluster_name" {
  type        = string
  description = "The name of the EKS cluster"
}

variable "openid_connect_provider_arn" {
  type        = string
  description = "The ARN of the OIDC Provider for the EKS cluster"
}

variable "openid_connect_provider_url" {
  type        = string
  description = "The URL of the OIDC Provider for the EKS cluster"
}

variable "namespace" {
  type        = string
  description = "The Kubernetes namespace where Karpenter will be deployed"
  default     = "karpenter"
}

variable "cluster_endpoint" {
  type        = string
  description = "The endpoint of the EKS cluster"
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to assign to the resources"
  default     = {}
}