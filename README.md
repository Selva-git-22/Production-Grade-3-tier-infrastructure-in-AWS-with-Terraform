# Production-Grade-3-tier-infrastructure-in-AWS-with-Terraform
A fully automated AWS infrastructure setup using Terraform. Spins up a production-grade environment with a load-balanced web tier, private compute, a managed MySQL database, and remote state management — all from scratch with a single `terraform apply`.

---

## What This Builds

Here's a quick picture of what gets created:

```
Internet
    │
    ▼
[Application Load Balancer]  ← public, spreads traffic across 2 AZs
    │
    ▼
[Auto Scaling Group]         ← 2–4 x t3.micro EC2 (Amazon Linux 2023, Apache)
    │         │
    │         └──(SSH via bastion)──▶ [Private EC2]  ← internal workloads
    │
    ▼
[RDS MySQL 8.0]              ← Multi-AZ, encrypted, private subnets only
```

Everything lives inside a custom VPC (`10.0.0.0/16`) spread across two availability zones in `us-east-1`. Public subnets hold the ALB and web servers; private subnets hold the database and internal EC2. A NAT Gateway gives private resources outbound internet access without exposing them inbound.

Terraform state is stored remotely in S3 with DynamoDB locking so multiple people can work on this safely without stepping on each other.

---

## Project Structure

```
.
├── bootstrap/              # Run this ONCE first to create the S3 + DynamoDB backend
│   └── main.tf
├── backend.tf              # S3 remote state configuration
├── main.tf                 # All core infrastructure (VPC, EC2, RDS, ALB, ASG...)
├── provider.tf             # AWS provider config
├── output.tf               # Useful values printed after apply
├── terraform.tfvars        # Your variable values (don't commit this!)
└── README.md
```

---

## Prerequisites

Before you start, you'll need:

- [Terraform](https://developer.hashicorp.com/terraform/downloads) v1.3 or newer
- AWS CLI configured (`aws configure`) with an IAM user that has sufficient permissions
- An SSH key pair on your local machine (`~/.ssh/id_rsa` and `~/.ssh/id_rsa.pub`)

---

## Getting Started

### Step 1 — Bootstrap the remote backend

This only needs to be done once. It creates the S3 bucket and DynamoDB table that store and lock your Terraform state.

```bash
cd bootstrap
terraform init
terraform apply
cd ..
```

### Step 2 — Fill in your variables

Open `terraform.tfvars` and update the values:

```hcl
my_ip           = "YOUR_ACTUAL_IP/32"   # run: curl ifconfig.me
db_password     = "YourStrongPassword"
public_key_path = "~/.ssh/id_rsa.pub"
```

> **Important:** Never commit `terraform.tfvars` to Git. It contains your IP and database password. Add it to `.gitignore`.

### Step 3 — Deploy

```bash
terraform init    # connects to the S3 backend
terraform plan    # review what will be created
terraform apply   # build everything
```

After apply completes, you'll see outputs like the ALB DNS name. Paste that into your browser and you should see the Apache welcome page served from one of the ASG instances.

### Tear it down

```bash
terraform destroy
```

Note: the S3 state bucket has `prevent_destroy = true` so it won't be deleted by this command. Delete it manually from the AWS console if you want to clean up completely.

---

## Infrastructure Details

### Networking

| Resource | CIDR / Details |
|---|---|
| VPC | `10.0.0.0/16` |
| Public Subnet A (us-east-1a) | `10.0.1.0/24` |
| Public Subnet B (us-east-1b) | `10.0.2.0/24` |
| Private Subnet A (us-east-1a) | `10.0.11.0/24` |
| Private Subnet B (us-east-1b) | `10.0.12.0/24` |
| NAT Gateway | Elastic IP, in Public Subnet A |

### Compute

- **Auto Scaling Group**: 2 desired / 2 min / 4 max, `t3.micro`, Amazon Linux 2023
- **Launch Template**: installs Apache (`httpd`) on boot via user data script
- **Private EC2**: single `t3.micro` in private subnet, accessible only via SSH from the public web instances (bastion pattern)

### Load Balancer

- Application Load Balancer across both public subnets
- HTTP listener on port 80 forwarding to the ASG target group
- Health check on `/` — instance marked healthy after 2 consecutive passes

### Database

| Setting | Value |
|---|---|
| Engine | MySQL 8.0 |
| Instance | db.t3.micro |
| Storage | 20 GB gp3, encrypted |
| Multi-AZ | Yes |
| Backup retention | 7 days |
| Publicly accessible | No |

### Security Group Rules (tiered)

```
Internet → ALB (port 80)
ALB → EC2 web tier (port 80)
Your IP → EC2 web tier (port 22, SSH)
EC2 web tier → Private EC2 (port 22, SSH)
EC2 web tier → RDS (port 3306, MySQL)
```

Each tier only accepts traffic from the tier directly above it. The database has no egress rule — it doesn't need outbound internet access.

### Remote State

| Resource | Name |
|---|---|
| S3 Bucket | `my-terraform-state-bucket-prod-26-05` |
| State file key | `prod/terraform.tfstate` |
| DynamoDB lock table | `terraform-state-lock` |

State is encrypted at rest, versioned (so you can roll back if something goes wrong), and locked during applies.

---

## Outputs

After `terraform apply` you'll get:

| Output | Description |
|---|---|
| `alb_dns_name` | Paste this in your browser to hit the web tier |
| `vpc_id` | VPC identifier |
| `public_subnet_ids` | IDs of both public subnets |
| `private_subnet_ids` | IDs of both private subnets |
| `private_ec2_private_ip` | IP to SSH into from the bastion |
| `rds_endpoint` | MySQL connection string (marked sensitive) |

---

## .gitignore

Make sure your `.gitignore` includes at minimum:

```
.terraform/
.terraform.lock.hcl
terraform.tfstate
terraform.tfstate.backup
terraform.tfvars
*.tfvars
```

---

## Tech Stack

`Terraform` · `AWS VPC` · `EC2 + ASG` · `Application Load Balancer` · `RDS MySQL` · `S3` · `DynamoDB` · `Amazon Linux 2023`
