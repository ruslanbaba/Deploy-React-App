# Deploy React App

A scalable, secure React app with modular Terraform infrastructure, multi-environment support (dev/qa/prod), and CI linting.

## Architecture at a glance

- Terraform modules
  - `network`: VPC, subnets, DNS settings
  - `compute`: Auto Scaling Group (ASG) + Application Load Balancer (ALB)
  - `security`: Security Groups + AWS WAF (managed rules)
  - `cdn`: CloudFront distribution for global caching
  - `monitoring`: CloudWatch Log Group and CPU alarm
- Multi-environment configuration via `terraform/tfvars/{dev,qa,prod}.tfvars`
- CI linting with TFLint + `terraform fmt` (GitHub Actions)
- Remote backend (S3 backend block present; configure bucket/DynamoDB outside this repo)

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

Suggested workspace flow (commands shown for reference; do not run here):

```bash
# one-time per machine
terraform init

# create/select workspace
terraform workspace new dev || terraform workspace select dev

# plan/apply with env vars
terraform plan -var-file=tfvars/dev.tfvars
terraform apply -var-file=tfvars/dev.tfvars
```

For `qa`/`prod`, replace the tfvars/workspace accordingly. Use least-privilege AWS credentials and a remote backend (S3 + DynamoDB lock) for team safety.

## CI: Terraform linting

- Runs on PRs touching `terraform/**` or `.tflint.hcl`
- Steps: `tflint` + `terraform fmt -check`
- Workflow: `.github/workflows/terraform-lint.yml`

To extend CI/CD:
- Add environment-scoped plan/apply jobs gated by PR labels or branches
- Use GitHub OIDC to assume AWS roles per environment (no long-lived secrets)

## 🔒 Security & Best Practices

### DevSecOps Pipeline
- **SAST (Static Application Security Testing)**
  - ESLint Security Plugin for JavaScript vulnerabilities
  - Semgrep for custom security rules and OWASP Top 10
  - npm audit for dependency vulnerabilities
  - Snyk for comprehensive dependency scanning
- **DAST (Dynamic Application Security Testing)**
  - OWASP ZAP baseline scan for runtime vulnerabilities
  - Automated security testing in CI/CD pipeline
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

Security workflows run on:
- All pushes to main/develop branches
- Pull requests to main branch
- Infrastructure changes in terraform/

## Scalability & performance

- ALB + ASG handle traffic spikes; tune min/max/desired capacity per env
- CloudFront CDN caches static assets globally and shields origin
- Multi-AZ subnets recommended for HA (expand `azs` and subnets in `network` module inputs)

## Monitoring & operations

- CloudWatch Log Group for app/infra logs
- CPU alarm example included (add SNS notification targets per your ops tooling)
- Tag all resources for cost tracking (project, env, owner)

## Using the modules (example root wiring)

You can migrate the root to use the new modules. Example snippet (for reference):

```hcl
module "network" {
  source           = "./modules/network"
  vpc_name         = var.vpc_name
  vpc_cidr         = "10.0.0.0/16"
  azs              = ["us-east-1a", "us-east-1b"]
  public_subnets   = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets  = ["10.0.11.0/24", "10.0.12.0/24"]
}

module "security" {
  source  = "./modules/security"
  sg_name = "react-app-sg"
  vpc_id  = module.network.vpc_id
  sg_rules = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
  waf_name = "react-app-waf"
}

module "compute" {
  source              = "./modules/compute"
  instance_name       = var.instance_name
  subnet_ids          = module.network.public_subnets
  min_size            = 2
  max_size            = 10
  desired_capacity    = 2
  alb_name            = "react-app-alb"
  alb_security_groups = [module.security.security_group_id]
}

module "cdn" {
  source             = "./modules/cdn"
  origin_domain_name = module.compute.alb_dns_name
}

module "monitoring" {
  source         = "./modules/monitoring"
  log_group_name = "react-app-logs"
  cpu_alarm_name = "react-app-cpu-alarm"
}
```

Adjust variables to match your `tfvars` files per environment.

## Frontend deployment options

- Static hosting: Build React (`npm run build`) and deploy `build/` to S3 + CloudFront (preferred for static SPAs)
- Server-origin: Serve via ALB/EC2 if you need SSR or custom backend; put CloudFront in front as cache/shield

## Getting started (local app)

```bash
npm install
npm test
npm start
```

## Roadmap / next steps

- Wire root Terraform fully to the new modules (phased migration from legacy `ec2` usage)
- Add GitHub Actions plan/apply workflows with OIDC and environment protections
- Add SNS topics/Slack notifications for alarms; expand metrics and dashboards
- Add cost budgets and anomaly detection
- Add WAF association to ALB/CloudFront explicitly as needed
