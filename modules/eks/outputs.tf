output "cluster_name" {
  description = "The exact name of the provisioned EKS cluster, utilized by downstream modules and helper scripts."
  value       = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  description = "The technical URL endpoint for the Kubernetes API server, used by kubectl, Helm, and Karpenter to communicate with the cluster."
  value       = aws_eks_cluster.this.endpoint
}

output "oidc_provider_arn" {
  description = "The Amazon Resource Name (ARN) of the OpenID Connect (OIDC) identity provider associated with the EKS cluster. Critical for IRSA configurations."
  value       = aws_iam_openid_connect_provider.eks.arn
}

output "oidc_provider_url" {
  description = "The issuer URL of the OpenID Connect (OIDC) identity provider, used to cross-reference Kubernetes service accounts with AWS IAM roles."
  value       = aws_iam_openid_connect_provider.eks.url
}