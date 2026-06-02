# AWS EKS Karpenter with Terraform

This project provisions an AWS EKS cluster and deploys Karpenter using Terraform. The architecture follows a hybrid node management strategy where system components run on ASG-managed nodes, while Karpenter dynamically provisions workload nodes.


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





