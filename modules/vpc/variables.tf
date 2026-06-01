variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "public_subnets" {
  description = "Public subnet CIDR blocks (3 AZs)"
  type        = list(string)
}

variable "private_subnets" {
  description = "Private subnet CIDR blocks (3 AZs)"
  type        = list(string)
}

variable "availability_zones" {
  description = "Availability zones (3 AZs)"
  type        = list(string)
}

variable "cluster_name" {
  description = "EKS cluster name for tagging"
  type        = string
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}