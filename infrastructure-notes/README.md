DevOps React App Infrastructure & Deployment

This repository contains:

Terraform code to provision AWS infrastructure (VPC, EC2, IAM, S3 backend)

A React app deployed to an EC2 instance using AWS SSM (no SSH)

GitHub Actions workflows for CI/CD and Terraform validation

├── terraform/               # Terraform infrastructure code
│   ├── main.tf              # Core infrastructure components (EC2, IAM roles, instance profile)
│   ├── network.tf           # VPC, subnet, and security group configuration
│   ├── provider.tf          # AWS provider and backend configuration
│   ├── variables.tf         # Input variables for modular and reusable code
│   ├── output.tf            # Outputs like EC2 public IP (if configured)
│   └── tfvars/              # Environment-specific variable definitions
├── src/                     # React app source
├── public/                  # React static content (index.html, favicon, etc.)
└── .github/workflows/       # CI/CD workflows

Terraform Infrastructure: File-by-File Breakdown

provider.tf

Defines the AWS provider version and backend configuration for remote state management. Using an S3 backend ensures that the Terraform state is not stored locally, which is critical for collaborative teams. Remote state also allows versioning, state locking, and recovery, which are essential in any real-world infrastructure as code (IaC) workflow. The configuration allows every infrastructure change to be reproducible, trackable, and shareable across environments and team members.

main.tf

This file defines the core infrastructure components:

IAM Role: Enables the EC2 instance to assume an identity with specific permissions. This avoids using hardcoded credentials or insecure key storage.

AmazonSSMManagedInstanceCore: Grants the EC2 instance permissions to register and interact with AWS Systems Manager. This allows us to manage and execute commands on the instance without opening port 22 or dealing with SSH key pairs. In secure enterprise environments, direct access to servers is discouraged or disallowed—SSM provides centralized, auditable, and secure administration.

AmazonS3ReadOnlyAccess: The EC2 instance does not need to write to S3. It only needs to pull down build.zip artifacts from S3. This managed policy provides the minimal permissions required for that action and avoids over-provisioning.

IAM Instance Profile: Connects the IAM role to the EC2 instance at launch time. This enables the EC2 to automatically assume its role and use the defined permissions for SSM and S3.

network.tf

Defines networking resources:

VPC: Provides logical isolation of the deployed infrastructure. Using a custom VPC enables us to control networking behaviors, IP ranges, DNS options, and more.

Subnet: A public subnet allows the EC2 instance to be accessible over the internet. This was necessary because we are serving a public-facing web app.

Security Group: Allows HTTP (port 80) inbound traffic. All outbound traffic is allowed so the instance can access internet resources (such as for updates or downloading the build artifact).

variables.tf

Allows configuration parameters to be reused and centrally defined. In a professional setting, infrastructure code is often deployed across multiple environments (dev, stage, prod), regions, and configurations. Using variables ensures flexibility and reduces duplication.

output.tf

Can be used to output important values such as the EC2 public IP address. This is helpful for debugging and quick access post-deployment.

tfvars/us-east-1.tfvars

Stores region-specific variable values. This separation enables the same Terraform code to be reused in different AWS regions or environments by simply passing in a different tfvars file.

Why These AWS Services Were Chosen

Amazon VPC

All production-grade applications should be deployed in a dedicated, isolated virtual network. Using a VPC allows us to control all network-level aspects including IP range, subnetting, routing, internet gateways, and DNS. It is the foundational element that supports both scalability and security.

Amazon EC2

Used in this demo to host the Apache web server and serve the React app. EC2 offers full control over the instance OS and network stack. Although more modern alternatives like S3 + CloudFront are recommended for static apps, EC2 was used here to simulate a traditional deployment pipeline and showcase SSM usage.

Amazon IAM

IAM roles and policies are used to grant the EC2 instance access to specific AWS services (S3 and SSM) without hardcoded credentials. Roles provide a secure, auditable way of granting AWS permissions. This aligns with enterprise-grade security practices.

Amazon S3

S3 is used in two contexts:

Terraform Backend – to store the Terraform state file, which enables safe, consistent, team-based deployments.

Deployment Artifact Store – to hold the built React application (build.zip) from CI. Using S3 as a staging point decouples build and deployment phases, which is essential in multi-stage pipelines and team workflows.

AWS Systems Manager (SSM)

One of the most security-conscious decisions in this setup is using SSM in place of SSH. SSM allows sending commands to EC2 instances via the AWS API without exposing the instance to the internet or requiring key pair authentication. This is not only safer but also easier to audit and manage at scale. It fits naturally into compliance requirements and reduces operational overhead.

.htaccess File: Purpose and Reasoning

Apache, by default, will return a 404 when a user visits a route like /dashboard because it tries to find a file called dashboard on the server. In a React Single Page Application (SPA), all routing is handled client-side. To ensure Apache always serves index.html for any unknown path, a rewrite rule is used.

The .htaccess file:
RewriteEngine On
RewriteBase /
RewriteRule ^index\.html$ - [L]
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule . /index.html [L]

This rewrite logic tells Apache: if a request doesn’t match a real file or directory, serve index.html. This is critical for React Router (or similar libraries) to function properly.

GitHub Actions Workflows: Terraform and Application

apply_pipeline.yml

Triggered on every push to main. This pipeline:

Extracts environment configuration from the tfvars file

Ensures the remote backend bucket exists

Runs terraform init with backend configuration

Applies infrastructure changes using terraform apply -auto-approve

This reflects a typical GitOps pipeline where infrastructure changes are deployed as code via version control.

plan_pipeline.yml

Triggered on pull requests that modify .tf or .yml files. This performs a terraform plan and provides visibility into what would change if the PR is merged. This is the foundation of GitOps and peer-reviewed infrastructure practices. It ensures:

No unintentional changes make it into production

Teams can review the impact of every infrastructure change before it happens

Infrastructure drift is caught early

This mirrors real enterprise workflows where plan-and-apply phases are split for security and compliance.

application_deployment.yml

Triggered when React source files change. The pipeline:

Runs npm install and npm run build

Zips the build/ directory

Uploads build.zip to S3

Uses aws ssm send-command to:

Install Apache and unzip tools (if not installed)

Download and unzip the artifact to /var/www/html

Deploy .htaccess to support SPA routing

Restart Apache to pick up new changes

This pipeline illustrates safe, repeatable deployment without direct access to the EC2 instance.

Enterprise-Grade Improvements

Area

Recommendation

Benefit

Security

Replace GitHub secrets with OIDC-based IAM role assumption using actions/aws-actions/configure-aws-credentials

Removes long-lived AWS credentials and improves security posture

IAM Least Privilege

Replace AmazonS3ReadOnlyAccess with a scoped inline policy limited to the specific bucket/prefix

Minimizes surface area in case of compromise

Audit Logging

Enable AWS CloudTrail and SSM Session Manager logging to S3 or CloudWatch

Auditable access to EC2 and deployment history

Hosting

Migrate to S3 + CloudFront for React builds (instead of EC2)

Eliminates server patching, supports instant rollback, and edge caching

Versioned Deployments

Upload builds to versioned S3 paths (e.g., /builds/v1.2.0/) and alias latest/

Enables rollback, semantic versioning, and better release visibility

Blue-Green/Canary

Use two EC2 instances or ALB target groups to shift traffic gradually during deploy

Zero downtime, safe rollouts

Monitoring

Integrate CloudWatch, Datadog, or Grafana dashboards for build health, deploy duration, and error rates

Production-grade visibility and alerts

Artifact Registry

Store build.zip in S3 with retention policies or use a centralized artifact repository

Improves traceability and compliance

Code Quality

Add linting, formatting, and test coverage enforcement to CI (e.g., ESLint, Jest coverage)

Ensures consistent, reliable code across teams

GitOps + Drift Detection

Add scheduled terraform plan jobs + terraform validate on PR

Prevents configuration drift and keeps infrastructure auditable

Performance

Enable CloudFront + Brotli + Gzip compression for JS/CSS assets

Reduces load time and improves user experience

Global Scaling

Add CloudFront + WAF and Route 53 for global, secure routing

Enterprise-grade availability and DDoS protection

Cost Optimization

Replace EC2 with S3 static site hosting for React

Eliminates compute costs and simplifies infra

Author

Created by Ruslan Babajanov