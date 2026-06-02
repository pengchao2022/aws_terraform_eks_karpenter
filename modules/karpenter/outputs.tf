output "karpenter_controller_role_arn" {
  description = "The ARN of the IAM role for the Karpenter controller"
  value       = aws_iam_role.karpenter_controller.arn
}