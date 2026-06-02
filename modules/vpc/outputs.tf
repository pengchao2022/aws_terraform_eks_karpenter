output "vpc_id" {
  description = "The unique identifier of the newly created custom VPC."
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "A list of identifiers for the allocated public subnets, typically used for external Load Balancers (ALB/NLB)."
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "A list of identifiers for the isolated private subnets where EKS cluster nodes and Karpenter dynamic instances will be securely provisioned."
  value       = aws_subnet.private[*].id
}