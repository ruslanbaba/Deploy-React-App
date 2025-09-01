# Deploy React App

A scalable, secure React app with modular Terraform infrastructure, multi-environment support (dev/qa/prod), and CI linting.

### Completed Infrastructure
- **Modular Terraform**: Full migration from legacy EC2 to modular architecture
- **Multi-Environment**: Complete dev/qa/prod support with workspace isolation
- **Auto-Scaling**: ASG + ALB with health checks and target groups
- **CDN**: CloudFront with WAF association and caching optimization
- **Security**: Enhanced WAF, GuardDuty, VPC Flow Logs, KMS encryption
- **Monitoring**: Comprehensive CloudWatch dashboards, alerts, and Slack notifications
- **Cost Management**: Budgets, anomaly detection, and cost allocation tagging
- **CI/CD**: OIDC-authenticated GitHub Actions for plan/apply workflows


## Repository structure

- `src/` React app with security-focused ESLint configuration
- `terraform/` root stack with enhanced security modules
  - `modules/`
    - `network/` – VPC with private subnets, flow logs, encryption
    - `compute/` – ASG + ALB with security groups
    - `security/` – Enhanced WAF, GuardDuty, security groups
    - `cdn/` – CloudFront distribution with security headers
    - `monitoring/` – CloudWatch with encrypted logs
    - `secrets/` – Secrets Manager and SSM Parameter Store
  - `tfvars/` – environment variable files
    - `dev.tfvars`, `qa.tfvars`, `prod.tfvars`
  - `provider.tf` – AWS provider + S3 backend
  - `variables.tf` – shared variables with security defaults
- `.github/workflows/` – CI/CD with security scanning
  - `security-scan.yml` – SAST/DAST for application code
  - `infra-security.yml` – Infrastructure security scanning
  - `terraform-lint.yml` – Terraform linting and formatting
- `Dockerfile` – Multi-stage build with security hardening
- `nginx.conf` – Security headers and best practices
- `.eslintrc.json` – ESLint with security plugins
- `.zap/rules.tsv` – OWASP ZAP scanning configuration

## Environments (dev, qa, prod)

Environment-specific values live in:
- `terraform/tfvars/dev.tfvars`
- `terraform/tfvars/qa.tfvars`
- `terraform/tfvars/prod.tfvars`


## CI: Terraform linting

- Runs on PRs touching `terraform/**` or `.tflint.hcl`
- Steps: `tflint` + `terraform fmt -check`
- Workflow: `.github/workflows/terraform-lint.yml`

    
- **Infrastructure Security**
  - Checkov for Terraform security compliance
  - TFSec for Terraform static analysis
  - Trivy for container image vulnerability scanning
  - TruffleHog for secrets detection in git history

### AWS Security Hardening
- **Network Security**
  - Private subnets for compute resources with NAT Gateway
  - VPC Flow Logs with CloudWatch integration
  - Security Groups with least-privilege rules
  - WAF with managed rule sets (Core, SQLi, Rate Limiting)
  - GuardDuty for threat detection
- **Access Control**
  - IAM roles with least privilege principle
  - No long-lived AWS access keys in CI/CD
  - GitHub OIDC for secure AWS authentication
- **Data Protection**
  - Secrets Manager for sensitive data (API keys, passwords)
  - SSM Parameter Store for non-sensitive configuration
  - KMS encryption for logs and secrets
  - S3 bucket encryption and public access blocking
- **Monitoring & Compliance**
  - CloudWatch for metrics, logs, and alarms
  - AWS Config for compliance monitoring
  - CloudTrail for API auditing

### Container Security
- Multi-stage Docker build with minimal attack surface
- Non-root user execution
- Security headers in nginx configuration
- Regular security updates in base images
- Vulnerability scanning with Trivy

### CI/CD Security Workflows
- `.github/workflows/security-scan.yml` - Application security testing
- `.github/workflows/infra-security.yml` - Infrastructure security scanning
- `.github/workflows/terraform-lint.yml` - Terraform linting and formatting
- `.github/workflows/dependency-security.yml` - Dependency vulnerability monitoring and auto-fix

Security workflows run on:
- All pushes to main/develop branches
- Pull requests to main branch
- Infrastructure changes in terraform/
- Weekly automated dependency scans
- Immediate alerts for critical vulnerabilities (Dependabot integration)

## Scalability & performance

- ALB + ASG handle traffic spikes; tune min/max/desired capacity per env
- CloudFront CDN caches static assets globally and shields origin
- Multi-AZ subnets recommended for HA (expand `azs` and subnets in `network` module inputs)

## Monitoring & operations

- CloudWatch Log Group for app/infra logs
- CPU alarm example included (add SNS notification targets per your ops tooling)
- Tag all resources for cost tracking (project, env, owner)




