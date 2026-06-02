variable "environment" {
  type        = string
  description = "The deployment environment name (e.g., dev, staging, prod) used for naming and tagging cluster components."
}

variable "cluster_name" {
  type        = string
  description = "The unique name of the EKS cluster. This name is referenced throughout the ecosystem, including Karpenter provisioning."
}

variable "cluster_version" {
  type        = string
  description = "The Kubernetes control plane version (e.g., 1.30) to deploy and maintain."
}

variable "vpc_id" {
  type        = string
  description = "The ID of the custom VPC where the EKS cluster control plane cross-account elastic network interfaces (ENIs) will be created."
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "A list of private subnet IDs where the EKS managed node groups and Karpenter dynamic worker nodes will be launched."
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "A list of public subnet IDs required by the EKS control plane to establish internet-facing inbound/outbound connectivity if needed."
}

variable "tags" {
  type        = map(string)
  description = "A standard map of resource tags inherited from the root module to enforce unified resource categorization."
  default     = {}
}

variable "desired_nodes" {
  type        = number
  description = "The target number of managed system worker nodes for the EKS cluster control plane infrastructure."
}