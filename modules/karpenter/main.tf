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

# Helm Release for Karpenter
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

  depends_on = [
    aws_iam_role_policy_attachment.karpenter_controller
  ]
}

# Karpenter NodePool Configuration - 免费套餐优化
resource "kubernetes_manifest" "karpenter_nodepool" {
  manifest = {
    apiVersion = "karpenter.sh/v1beta1"
    kind       = "NodePool"
    metadata = {
      name = "default"
    }
    spec = {
      template = {
        spec = {
          nodeClassRef = {
            name = "default"
          }
          requirements = [
            {
              key      = "kubernetes.io/arch"
              operator = "In"
              values   = [var.architecture]
            },
            {
              key      = "kubernetes.io/os"
              operator = "In"
              values   = ["linux"]
            },
            {
              key      = "karpenter.k8s.aws/instance-family"
              operator = "In"
              values   = var.instance_families
            },
            {
              key      = "karpenter.k8s.aws/instance-size"
              operator = "In"
              values   = var.instance_sizes
            },
            {
              key      = "karpenter.sh/capacity-type"
              operator = "In"
              values   = ["on-demand"]
            }
          ]
          taints = []
          startupTaints = []
        }
      }
      limits = {
        cpu    = "4"
        memory = "8Gi"
      }
      disruption = {
        consolidationPolicy = "WhenUnderutilized"
        expireAfter         = "720h"
      }
    }
  }

  depends_on = [helm_release.karpenter]
}

# Karpenter EC2NodeClass Configuration - Ubuntu
resource "kubernetes_manifest" "karpenter_ec2nodeclass" {
  manifest = {
    apiVersion = "karpenter.k8s.aws/v1beta1"
    kind       = "EC2NodeClass"
    metadata = {
      name = "default"
    }
    spec = {
      amiFamily = "Ubuntu"
      amiSelectorTerms = [
        {
          name = "ubuntu-eks-${var.kubernetes_version}-*"
        }
      ]
      role = "KarpenterNodeRole-${var.cluster_name}"
      subnetSelectorTerms = [
        {
          tags = {
            "karpenter.sh/discovery" = var.cluster_name
          }
        }
      ]
      securityGroupSelectorTerms = [
        {
          tags = {
            "aws:eks:cluster-name" = var.cluster_name
          }
        }
      ]
      tags = {
        "karpenter.sh/discovery" = var.cluster_name
        "Name"                   = "${var.cluster_name}-node"
      }
      userData = base64encode(<<-EOF
        #!/bin/bash
        set -ex
        cat <<-KUBELET > /etc/default/kubelet
        KUBELET_EXTRA_ARGS="--node-labels=node.kubernetes.io/lifecycle=normal"
        KUBELET
      EOF
      )
    }
  }

  depends_on = [helm_release.karpenter]
}

# 保持节点的 Deployment - 免费套餐使用较小的资源请求
resource "kubernetes_deployment" "keep_nodes" {
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