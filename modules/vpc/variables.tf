variable "environment" {
  type        = string
  description = "The deployment environment name (e.g., dev, staging, prod) used to prefix network resources."
}

variable "cluster_name" {
  type        = string
  description = "The name of the EKS cluster. This is critical for matching the internal and external load balancer discovery tags."
}

variable "vpc_cidr" {
  type        = string
  description = "The overall CIDR block for the custom VPC (e.g., 10.0.0.0/16)."
}

variable "public_subnets" {
  type        = list(string)
  description = "A list of CIDR blocks for allocating the public subnets (typically 3 subnets for high availability)."
}

variable "private_subnets" {
  type        = list(string)
  description = "A list of CIDR blocks for allocating the private subnets where EKS worker nodes and Karpenter will reside."
}

variable "availability_zones" {
  type        = list(string)
  description = "A list of AWS Availability Zones (AZs) in the current region where subnets will be evenly distributed."
}

variable "tags" {
  type        = map(string)
  description = "A standard map of resource tags passed from the root module to ensure consistent billing and tracking."
  default     = {}
}