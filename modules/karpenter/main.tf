# Karpenter Controller IAM Role
resource "aws_iam_role" "karpenter_controller" {
  name = "${var.cluster_name}-karpenter-controller"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = var.openid_connect_provider_arn
        }
        Condition = {
          StringEquals = {
            "${replace(var.openid_connect_provider_url, "https://", "")}:aud" = "sts.amazonaws.com"
            "${replace(var.openid_connect_provider_url, "https://", "")}:sub" = "system:serviceaccount:${var.namespace}:karpenter"
          }
        }
      }
    ]
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
          "ec2:DescribeImages",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeLaunchTemplates",
          "ec2:DescribeInstances",
          "ec2:CreateFleet",
          "ec2:CreateLaunchTemplate",
          "ec2:CreateTags",
          "ec2:RunInstances",
          "ec2:TerminateInstances",
          "ec2:DeleteLaunchTemplate",
          "iam:PassRole",
          "ssm:GetParameter"
        ]
        Resource = ["*"]
      },
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster"
        ]
        Resource = ["*"]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "karpenter_controller" {
  role       = aws_iam_role.karpenter_controller.name
  policy_arn = aws_iam_policy.karpenter_controller.arn
}

# Helm Release for Karpenter (只负责安装核心脑子和 CRD 架构)
resource "helm_release" "karpenter" {
  name       = "karpenter"
  repository = "https://charts.karpenter.sh"
  chart      = "karpenter"
  version    = var.karpenter_version
  namespace  = var.namespace

  create_namespace = true

  values = [
    <<-EOT
serviceAccount:
  annotations:
    eks.amazonaws.com/role-arn: ${aws_iam_role.karpenter_controller.arn}
settings:
  clusterName: ${var.cluster_name}
  clusterEndpoint: ${var.cluster_endpoint}
  interruptionQueue: ${var.cluster_name}
controller:
  resources:
    requests:
      cpu: 100m
      memory: 256Mi
    limits:
      cpu: 1
      memory: 1Gi
EOT
  ]

  # 🌟 保持模块内部的干净依赖，确保 Helm 安装前 IAM 策略已经就绪
  depends_on = [
    aws_iam_role_policy_attachment.karpenter_controller
  ]
}

# 保持节点的 Deployment
resource "kubernetes_deployment_v1" "keep_nodes" {
  metadata {
    name      = "keep-nodes"
    namespace = "default"
  }

  spec {
    replicas = var.desired_nodes

    selector {
      match_labels = {
        app = "keep-nodes"
      }
    }

    template {
      metadata {
        labels = {
          app = "keep-nodes"
        }
      }

      spec {
        toleration {
          operator = "Exists"
        }

        affinity {
          pod_anti_affinity {
            preferred_during_scheduling_ignored_during_execution {
              weight = 100
              pod_affinity_term {
                label_selector {
                  match_expressions {
                    key      = "app"
                    operator = "In"
                    values   = ["keep-nodes"]
                  }
                }
                topology_key = "kubernetes.io/hostname"
              }
            }
          }
        }

        container {
          name  = "pause"
          image = "public.ecr.aws/eks-distro/kubernetes/pause:3.7"

          resources {
            requests = {
              cpu    = "50m"
              memory = "64Mi"
            }
            limits = {
              cpu    = "100m"
              memory = "128Mi"
            }
          }
        }

        termination_grace_period_seconds = 30
      }
    }
  }

  depends_on = [helm_release.karpenter]
}