# AWS EKS Karpenter with Terraform

This project provisions an AWS EKS cluster and deploys Karpenter using Terraform. The architecture follows a hybrid node management strategy where system components run on ASG-managed nodes, while Karpenter dynamically provisions workload nodes.

I also need added intergrated ArgoCD on EKS to make it a GitOps platform


### Node Management Strategy

| Node Type | Managed By | Purpose |
|-----------|------------|---------|
| **System Nodes** | Auto Scaling Group (ASG) | Run Karpenter Pod (the brain) and system components |
| **Workload Nodes** | Karpenter (direct management) | Dynamically provision t3.micro/small/medium instances as home for workload Pods |

**How It Works:**
1. ASG-managed system nodes host the Karpenter controller pod
2. Karpenter continuously monitors for pending workload pods
3. When demand increases, Karpenter dynamically provisions EC2 instances from AWS
4. When demand decreases, Karpenter automatically scales down idle nodes


## Prerequisites

- AWS Account with appropriate permissions
- GitHub repository with OIDC configured
- Terraform state backend (S3 bucket + DynamoDB table)
- AWS CLI configured locally for testing

- S3 bucket used for storage to store terraform.tfstate file
- Dynamodb used for locking 

## GitHub Secrets Configuration

| Secret Name | Description |
|-------------|-------------|
| `AWS_ROLE_ARN` | IAM Role ARN for GitHub Actions OIDC authentication |


## Terraform State Management

State is stored remotely in S3 with DynamoDB for state locking:

```hcl
terraform {
  backend "s3" {
    bucket         = "your-terraform-state-bucket"
    key            = "eks-karpenter/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}
```

## Connect to EKS cluster

```shell
aws eks update-kubeconfig --region us-east-1 --name allen-eks-karpenter

```
## Check the EKS nodes

```shell
allen@allens-MacBook-Pro devops % kubectl get nodes
NAME                          STATUS   ROLES    AGE   VERSION
ip-10-0-11-142.ec2.internal   Ready    <none>   17m   v1.30.14-eks-ecaa3a6
ip-10-0-12-114.ec2.internal   Ready    <none>   17m   v1.30.14-eks-ecaa3a6
ip-10-0-13-234.ec2.internal   Ready    <none>   17m   v1.30.14-eks-ecaa3a6
```
## Check the karpenter pods

```shell
allen@allens-MacBook-Pro devops % kubectl get pods -n karpenter
NAME                         READY   STATUS    RESTARTS   AGE
karpenter-56fd6c799f-rh7sl   1/1     Running   0          16m
```

## Check the ArgoCD public URL and password after deployed
```shell
kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'; echo
```

```shell
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath={.data.password} | base64 -d; echo
```
ArgoCD default username is: admin

## Upgrade EKS 
- when you try to upgrade EKS you need to modified the following versions in your terrafrom tf files:

  - eks cluster version
  - vpc_cni_version
  - coredns_version   
  - kube_proxy_version 
  - ami_type 


## New added
- Added ebs-csi controller install by terraform also added IRSA for ebs csi driver 
```shell
resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = "aws-ebs-csi-driver"
  addon_version               = var.ebs_csi_version
  service_account_role_arn = aws_iam_role.ebs_csi_controller_role.arn
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  
  depends_on = [aws_eks_node_group.system]
}
```
- IRSA
```shell
# EBS CSI Driver IAM Role (IRSA)
resource "aws_iam_role" "ebs_csi_controller_role" {
  name = "ebs-csi-controller-role-${var.cluster_name}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRoleWithWebIdentity"
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.eks.arn
      }
      Condition = {
        StringEquals = {
          "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
        }
      }
    }]
  })
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ebs_csi_controller_policy" {
  role       = aws_iam_role.ebs_csi_controller_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

- Check the ebs csi controller on EKS

```shell
allen@192 aws_terraform_eks_karpenter % kubectl get pods -n kube-system | grep ebs-csi
ebs-csi-controller-55574d4b76-f7wrx   6/6     Running   0          10m
ebs-csi-controller-55574d4b76-hnrjv   6/6     Running   0          10m
ebs-csi-node-fd5zt                    3/3     Running   0          10m
ebs-csi-node-htrqv                    3/3     Running   0          10m
ebs-csi-node-kt87x                    3/3     Running   0          10m
ebs-csi-node-mx89r                    3/3     Running   0          10m
```

## Difference between count and for_each in Terraform

### count 

   count 接收一个整数（Integer），表示你需要创建资源的份数。适用完全相同的资源，且资源之间不需要特殊的唯一标识，或者仅仅是需要创建多个个副本，在资源内部通过 count.index 来获取当前是第几个资源（从 0 开始）

- 如 创建 3 个相同的 EC2 主机
```shell
resource "aws_instance" "web" {
  count         = 3
  ami           = "ami-0c101f26f147fa7fd" # 请替换为你所在区域有效的 AMI ID
  instance_type = "t3.micro"

  tags = {
    Name = "my-instance-${count.index}"
  }
}
```

### for_each

  for_each 接收一个映射（Map）或集合（Set）。它会遍历集合中的每一个元素，并为每个元素创建一个资源实例。适用于资源配置略有不同，或者你有明确的 Key-Value 对应关系。数据引用在资源内部，通过 each.key 和 each.value 来访问当前遍历到的项。

- 如 为不同环境创建不同的 VPC 

```shell
variable "environments" {
  default = {
    dev  = "10.0.1.0/24"
    prod = "10.0.2.0/24"
  }
}

resource "aws_vpc" "this" {
  for_each   = var.environments
  cidr_block = each.value # 使用 value
  tags = {
    Name = each.key       # 使用 key (dev, prod)
  }
}
```
- 核心对比
| 特性 | `count`（基于索引） | `for_each`（基于 Map Key 或 Set 元素） |
|------|-------------------|---------------------------------------|
| 输入类型 | 整数 (Integer) | Map 或 Set |
| 唯一标识 | 基于索引 (0, 1, 2...) | 基于 Map 的 Key 或 Set 的元素 |
| 灵活性 | 低，删除中间一个会导致后续资源全部被重建 | 高，删除中间一个只会影响该实例，其他不受影响 |
| 适用范围 | 完全一样的克隆资源 | 每个资源有独立配置的集合 |










