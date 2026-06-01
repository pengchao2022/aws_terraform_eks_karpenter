# EKS 集群角色
resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.cluster_name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# EKS 集群
resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  # 🌟 修复 Bug：原代码写的是 aws_iam_role.cluster.arn，实际应该引用你上面定义的 eks_cluster_role
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = var.cluster_version

  vpc_config {
    subnet_ids              = concat(var.private_subnet_ids, var.public_subnet_ids)
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  lifecycle {
    ignore_changes = [
      compute_config,
      bootstrap_self_managed_addons
    ]
  }

  # 🌟 核心新增 1：强依赖 EKS 角色策略绑定
  # 确保 AWS 在给这个 Role 成功注入官方托管策略后，再开始创建集群底座。避免报 400 AccessDenied
  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]
}

# OIDC Provider
data "tls_certificate" "eks" {
  url = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.this.identity[0].oidc[0].issuer

  tags = var.tags
}

# ==========================================
# ✨ AWS 托管节点组（用于运行系统组件）
# ==========================================
resource "aws_eks_node_group" "system" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.cluster_name}-system-nodes"
  node_role_arn   = aws_iam_role.karpenter_node_role.arn
  subnet_ids      = var.private_subnet_ids

  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }

  ami_type       = "AL2_x86_64"
  instance_types = ["t3.micro"]

  labels = {
    "role" = "system"
  }

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-system-nodes"
  })

  # 这里你的 depends_on 设计得非常好，继续保持！
  depends_on = [
    aws_iam_role_policy_attachment.karpenter_node,
    aws_eks_cluster.this
  ]
}

# ==========================================
# 🔧 优化：EKS Add-ons（全部加固显式依赖）
# ==========================================
resource "aws_eks_addon" "coredns" {
  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = "coredns"
  addon_version               = "v1.11.1-eksbuild.6"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [aws_eks_node_group.system]
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = "kube-proxy"
  addon_version               = "v1.29.0-eksbuild.2"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  # 🌟 核心优化 2：kube-proxy 是底层核心网络组件，它需要集群和网络完全稳定后装入
  depends_on = [aws_eks_cluster.this]
}

resource "aws_eks_addon" "vpc_cni" {
  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = "vpc-cni"
  addon_version               = "v1.18.1-eksbuild.1"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  # 🌟 核心优化 3：vpc-cni 负责节点网卡分配，必须等节点组的 IAM 权限附加完、集群诞生后再开始装
  depends_on = [
    aws_eks_cluster.this,
    aws_iam_role_policy_attachment.karpenter_node
  ]
}

# Karpenter 节点 IAM 角色
resource "aws_iam_role" "karpenter_node_role" {
  name = "KarpenterNodeRole-${var.cluster_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# 附加策略到 Karpenter 节点角色
resource "aws_iam_role_policy_attachment" "karpenter_node" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  ])

  role       = aws_iam_role.karpenter_node_role.name
  policy_arn = each.value
}

# Karpenter 节点实例配置文件
resource "aws_iam_instance_profile" "karpenter" {
  name = "KarpenterNodeInstanceProfile-${var.cluster_name}"
  role = aws_iam_role.karpenter_node_role.name
}