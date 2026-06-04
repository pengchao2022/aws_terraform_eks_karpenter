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









