resource "aws_iam_role" "karpenter_controller" {
  name = "${var.cluster_name}-karpenter-controller"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRoleWithWebIdentity"
      Effect = "Allow"
      Principal = { Federated = var.openid_connect_provider_arn }
      Condition = {
        StringEquals = {
          "${replace(var.openid_connect_provider_url, "https://", "")}:aud" = "sts.amazonaws.com"
          "${replace(var.openid_connect_provider_url, "https://", "")}:sub" = "system:serviceaccount:${var.namespace}:karpenter"
        }
      }
    }]
  })
  
  tags = var.tags
}

resource "aws_iam_policy" "karpenter_controller" {
  name = "${var.cluster_name}-karpenter-policy"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          # EC2 resouces access
          "ec2:DescribeImages", "ec2:DescribeInstanceTypes", "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups", "ec2:DescribeLaunchTemplates", "ec2:DescribeInstances",
          "ec2:CreateFleet", "ec2:CreateLaunchTemplate", "ec2:CreateTags",
          "ec2:RunInstances", "ec2:TerminateInstances", "ec2:DeleteLaunchTemplate",
          "ssm:GetParameter",
          
          # Karpenter IAM role for node create
          "iam:GetInstanceProfile",
          "iam:PassRole",
          "iam:TagRole",
          "iam:TagInstanceProfile",
          "iam:CreateInstanceProfile",
          "iam:DeleteInstanceProfile",
          "iam:AddRoleToInstanceProfile",
          "iam:RemoveRoleFromInstanceProfile"
        ]
        Resource = ["*"]
      },
      { 
        Effect = "Allow", 
        Action = ["eks:DescribeCluster"], 
        Resource = ["*"] 
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "karpenter_controller" {
  role       = aws_iam_role.karpenter_controller.name
  policy_arn = aws_iam_policy.karpenter_controller.arn
}