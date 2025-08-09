# OIDC Setup Instructions for GitHub Actions

This document provides instructions for setting up OpenID Connect (OIDC) authentication between GitHub Actions and AWS for secure Terraform deployments.

## AWS Setup

### 1. Create OIDC Identity Provider

```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

### 2. Create IAM Roles for Each Environment

Create separate IAM roles for dev, qa, and prod environments:

```bash
# Dev Environment Role
aws iam create-role \
  --role-name GitHubActions-ReactApp-Dev \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Federated": "arn:aws:iam::ACCOUNT-ID:oidc-provider/token.actions.githubusercontent.com"
        },
        "Action": "sts:AssumeRole",
        "Condition": {
          "StringEquals": {
            "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
            "token.actions.githubusercontent.com:sub": "repo:YOUR-USERNAME/Deploy-React-App:environment:dev"
          }
        }
      }
    ]
  }'

# Attach policies to the role
aws iam attach-role-policy \
  --role-name GitHubActions-ReactApp-Dev \
  --policy-arn arn:aws:iam::aws:policy/PowerUserAccess
```

### 3. Create S3 Buckets and DynamoDB Tables for Terraform State

```bash
# Create S3 buckets for each environment
aws s3 mb s3://react-app-terraform-state-dev-RANDOM-SUFFIX
aws s3 mb s3://react-app-terraform-state-qa-RANDOM-SUFFIX
aws s3 mb s3://react-app-terraform-state-prod-RANDOM-SUFFIX

# Create DynamoDB tables for state locking
aws dynamodb create-table \
  --table-name react-app-terraform-locks-dev \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```

## GitHub Setup

### 1. Configure Repository Secrets

Add the following secrets to your GitHub repository:

```
AWS_ROLE_ARN_DEV: arn:aws:iam::ACCOUNT-ID:role/GitHubActions-ReactApp-Dev
AWS_ROLE_ARN_QA: arn:aws:iam::ACCOUNT-ID:role/GitHubActions-ReactApp-QA
AWS_ROLE_ARN_PROD: arn:aws:iam::ACCOUNT-ID:role/GitHubActions-ReactApp-Prod

TF_STATE_BUCKET_DEV: react-app-terraform-state-dev-RANDOM-SUFFIX
TF_STATE_BUCKET_QA: react-app-terraform-state-qa-RANDOM-SUFFIX
TF_STATE_BUCKET_PROD: react-app-terraform-state-prod-RANDOM-SUFFIX

TF_STATE_LOCK_TABLE_DEV: react-app-terraform-locks-dev
TF_STATE_LOCK_TABLE_QA: react-app-terraform-locks-qa
TF_STATE_LOCK_TABLE_PROD: react-app-terraform-locks-prod
```

### 2. Configure Environment Protection Rules

In your GitHub repository settings:
1. Go to Settings → Environments
2. Create environments: `dev`, `qa`, `prod`
3. For `qa` and `prod`, add protection rules:
   - Required reviewers
   - Wait timer
   - Deployment branches (restrict to main branch)

## Security Best Practices

1. **Least Privilege**: Each environment role should only have permissions for its specific resources
2. **Environment Isolation**: Use separate AWS accounts for production
3. **State Management**: Enable versioning and encryption on S3 state buckets
4. **Monitoring**: Enable CloudTrail logging for all API calls
5. **Regular Rotation**: Rotate OIDC thumbprints and review permissions quarterly

## Usage

- **Plan**: Automatically runs on PRs to show changes
- **Apply**: 
  - Dev: Automatically deploys on merge to main
  - QA/Prod: Manual deployment via workflow_dispatch with approval gates
