# ========================================================
# EKS 核心集群角色
# ========================================================
resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.cluster_name}-cluster-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "eks.amazonaws.com" } }]
  })
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# ========================================================
# EKS 集群本体 (锁定 1.30)
# ========================================================
resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = "1.30" # 保持写死 1.30 杜绝降级隐患

  vpc_config {
    subnet_ids              = concat(var.private_subnet_ids, var.public_subnet_ids)
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  # 🌟 修复点 1：开启 API 访问条目认证，并自动允许创建者（GitHub Actions）拥有管理员权限
  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  bootstrap_self_managed_addons = false

  # 🌟 修复点 2：必须把 access_config 从 ignore_changes 中删掉，否则上方新加的配置不会生效！
  lifecycle {
    ignore_changes = [
      bootstrap_self_managed_addons
    ]
  }

  depends_on = [aws_iam_role_policy_attachment.eks_cluster_policy]
}

# OIDC 用于 ServiceAccount 鉴权
data "tls_certificate" "eks" { url = aws_eks_cluster.this.identity[0].oidc[0].issuer }

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.this.identity[0].oidc[0].issuer
  tags            = var.tags
}

# ========================================================
# 托管系统组件的小型节点组 (自适应变量控制)
# ========================================================
resource "aws_eks_node_group" "system" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.cluster_name}-system-nodes"
  node_role_arn   = aws_iam_role.karpenter_node_role.arn
  subnet_ids      = var.private_subnet_ids

  scaling_config {
    desired_size = var.desired_nodes
    max_size     = var.desired_nodes + 3
    min_size     = var.desired_nodes
  }

  ami_type       = "AL2_x86_64"
  instance_types = ["t3.micro"]

  labels = {
    "role" = "system"
  }

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-system-nodes"
  })

  depends_on = [
    aws_iam_role_policy_attachment.karpenter_node, 
    aws_eks_cluster.this
  ]
}

# ========================================================
# EKS Add-ons 插件自动化配置
# ========================================================
resource "aws_eks_addon" "coredns" {
  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = "coredns"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  depends_on                  = [aws_eks_node_group.system]
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = "kube-proxy"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  depends_on                  = [aws_eks_node_group.system]
}

resource "aws_eks_addon" "vpc_cni" {
  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = "vpc-cni"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  depends_on                  = [aws_eks_cluster.this, aws_iam_role_policy_attachment.karpenter_node]
}

# ========================================================
# 基础节点 IAM 角色与实例配置文件
# ========================================================
resource "aws_iam_role" "karpenter_node_role" {
  name = "KarpenterNodeRole-${var.cluster_name}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "ec2.amazonaws.com" } }]
  })
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "karpenter_node" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ])
  role       = aws_iam_role.karpenter_node_role.name
  policy_arn = each.value
}

resource "aws_iam_instance_profile" "karpenter" {
  name = "KarpenterNodeInstanceProfile-${var.cluster_name}"
  role = aws_iam_role.karpenter_node_role.name
}

# ========================================================
# 🌟 新增：为 Mac 本地 User/Allen 自动打通超级管理员通道
# ========================================================
resource "aws_eks_access_entry" "allen" {
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = "arn:aws:iam::317429619308:user/allen"
  type          = "STANDARD"
}

# ========================================================
# 🌟 修复格式：为你（user/allen）绑定官方最强的超级管理员策略
# ========================================================
resource "aws_eks_access_policy_association" "allen_admin" {
  cluster_name  = aws_eks_cluster.this.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy" # 🚀 黄金修复：改用 EKS 专属的官方内置访问策略 ARN
  principal_arn = "arn:aws:iam::317429619308:user/allen"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.allen]
}