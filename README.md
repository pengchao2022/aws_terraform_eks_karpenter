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








