# aws_terraform_eks_karpenter
terraform demo



## clarification

系统节点（ASG 管理） ───> 运行 Karpenter Pod (大脑)

业务节点（Karpenter 直管） ───> 动态向 AWS 批发各种 t3.micro/small/medium 实例 (业务 Pod 的家)