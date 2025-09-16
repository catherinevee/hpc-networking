# HPC Networking Infrastructure

This directory contains the complete Terragrunt-based infrastructure for deploying a high-performance computing (HPC) networking environment on AWS with secure GitHub Actions CI/CD integration.

## Architecture Overview

The infrastructure is designed for scientific computing workloads with the following key components:

- **Compute**: AWS ParallelCluster with Slurm scheduler
- **Networking**: EFA-enabled instances with cluster placement groups
- **Storage**: FSx Lustre for high-performance parallel file system
- **Monitoring**: CloudWatch, Grafana, and Prometheus
- **Security**: VPC with private subnets, security groups, and encryption
- **CI/CD**: GitHub Actions with OIDC authentication for secure AWS access

## Directory Structure

```
infrastructure/
├── terragrunt.hcl                    # Root configuration
├── _envcommon/                       # Shared configurations
│   ├── hpc-cluster.hcl              # ParallelCluster config
│   ├── networking.hcl               # Network settings
│   ├── storage.hcl                  # Storage configuration
│   └── monitoring.hcl               # Observability
├── modules/                          # Custom modules
│   ├── efa-network/                 # EFA configuration
│   ├── parallel-cluster/            # Cluster setup
│   ├── lustre-config/               # FSx optimization
│   └── slurm-accounting/            # Job accounting
├── dev/                             # Development environment
│   ├── account.hcl
│   ├── env.hcl
│   └── us-east-2/
│       ├── region.hcl
│       ├── networking/
│       │   ├── vpc/
│       │   │   └── terragrunt.hcl
│       │   ├── efa-sg/
│       │   │   └── terragrunt.hcl
│       │   ├── transit-gateway/
│       │   │   └── terragrunt.hcl
│       │   └── direct-connect/
│       │       └── terragrunt.hcl
│       ├── compute/
│       │   ├── parallel-cluster/
│       │   │   └── terragrunt.hcl
│       │   ├── batch-compute/
│       │   │   └── terragrunt.hcl
│       │   └── ec2-fleet/
│       │       └── terragrunt.hcl
│       ├── storage/
│       │   ├── fsx-lustre-scratch/
│       │   │   └── terragrunt.hcl
│       │   ├── fsx-lustre-persistent/
│       │   │   └── terragrunt.hcl
│       │   ├── s3-data-repository/
│       │   │   └── terragrunt.hcl
│       │   └── efs-home-dirs/
│       │       └── terragrunt.hcl
│       ├── management/
│       │   ├── bastion/
│       │   │   └── terragrunt.hcl
│       │   ├── scheduler/
│       │   │   └── terragrunt.hcl
│       │   └── license-server/
│       │       └── terragrunt.hcl
│       └── monitoring/
│           ├── cloudwatch/
│           │   └── terragrunt.hcl
│           ├── grafana/
│           │   └── terragrunt.hcl
│           └── flow-logs/
│               └── terragrunt.hcl
├── staging/                         # Staging environment
│   └── [similar structure]
└── production/                      # Production environment
    ├── us-east-2/
    ├── eu-west-1/
    └── ap-northeast-1/
```

## Prerequisites

1. **AWS CLI** configured with appropriate credentials
2. **Terraform** >= 1.5.0
3. **Terragrunt** >= 0.50.0
4. **AWS ParallelCluster** >= 3.7.0
5. **Git** for cloning the repository
6. **GitHub CLI** (optional, for repository setup)

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/your-org/hpc-networking.git
cd hpc-networking
```

### 2. Configure AWS Credentials

```bash
aws configure
# or
export AWS_ACCESS_KEY_ID=your_access_key
export AWS_SECRET_ACCESS_KEY=your_secret_key
export AWS_DEFAULT_REGION=us-east-2
```

### 3. Setup GitHub OIDC (Recommended)

For secure CI/CD integration, set up GitHub OIDC authentication:

```bash
# Linux/macOS
./scripts/setup-github-oidc.sh

# Windows PowerShell
.\scripts\setup-github-oidc.ps1 -GitHubOrg "your-org" -GitHubRepo "hpc-networking"
```

This creates an IAM role that GitHub Actions can assume without storing AWS credentials as secrets.

### 4. Deploy Infrastructure

#### Development Environment

```bash
# Navigate to dev environment
cd infrastructure/dev/us-east-2

# Deploy networking
cd networking
terragrunt run-all apply

# Deploy storage
cd ../storage
terragrunt run-all apply

# Deploy compute
cd ../compute
terragrunt run-all apply

# Deploy monitoring
cd ../monitoring
terragrunt run-all apply
```

#### Production Environment

```bash
# Navigate to production environment
cd infrastructure/production/us-east-2

# Deploy all components
terragrunt run-all apply
```

### 5. Deploy ParallelCluster

```bash
# Create cluster
pcluster create-cluster \
  --cluster-name hpc-dev \
  --cluster-configuration cluster-configs/dev.yaml \
  --region us-east-2
```

## GitHub Actions CI/CD

The infrastructure includes automated CI/CD pipelines using GitHub Actions with secure OIDC authentication.

### Workflow Features

- **Automated Deployment**: Deploy infrastructure on push to main/develop branches
- **Validation**: Network, storage, and compute configuration validation
- **Testing**: MPI communication, EFA functionality, and storage performance tests
- **Benchmarking**: Network performance tests with OSU micro-benchmarks
- **Cost Analysis**: Monthly cost tracking and optimization recommendations

### Security

- **OIDC Authentication**: No long-lived AWS credentials stored in GitHub
- **Repository-Specific Access**: Limited to specific repository and branches
- **Temporary Credentials**: Short-lived tokens with automatic expiration
- **Audit Trail**: Complete logging of all AWS API calls

### Manual Triggers

Use GitHub Actions workflow dispatch for manual operations:

```bash
# Trigger deployment via GitHub CLI
gh workflow run hpc-deploy.yml \
  --field environment=dev \
  --field action=apply \
  --field region=us-east-2
```

## Configuration

### Environment Variables

Set the following environment variables before deployment:

```bash
export TF_VAR_environment=dev
export TF_VAR_aws_region=us-east-2
export TF_VAR_cluster_name=hpc-dev
```

### Customization

#### Instance Types

Modify instance types in `_envcommon/hpc-cluster.hcl`:

```hcl
instance_types = {
  compute = "c5n.18xlarge"  # HPC optimized
  memory  = "x2iezn.32xlarge"  # Memory optimized
  gpu     = "p4d.24xlarge"  # GPU instances
}
```

#### Storage Configuration

Adjust storage sizes in `_envcommon/storage.hcl`:

```hcl
fsx_lustre_config = {
  scratch = {
    storage_capacity = 500  # TB
    per_unit_storage_throughput = 200  # MB/s per TiB
  }
}
```

#### Network Configuration

Modify VPC settings in `_envcommon/networking.hcl`:

```hcl
vpc_config = {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true
}
```

## Deployment Scripts

The project includes automated deployment scripts for easy infrastructure management.

### HPC Deployment Script

```bash
# Deploy dev environment
./scripts/deploy-hpc.sh --environment dev --action apply

# Scale cluster to 100 nodes
./scripts/deploy-hpc.sh --environment dev --action scale-up --cluster-size 100

# Destroy staging environment
./scripts/deploy-hpc.sh --environment staging --action destroy
```

### GitHub OIDC Setup Scripts

```bash
# Linux/macOS
./scripts/setup-github-oidc.sh

# Windows PowerShell
.\scripts\setup-github-oidc.ps1 -GitHubOrg "your-org" -GitHubRepo "hpc-networking"
```

## Monitoring

### CloudWatch Dashboards

Access CloudWatch dashboards for:
- Cluster utilization
- Job queue status
- Network performance
- Storage I/O

### Grafana Dashboards

Grafana provides detailed HPC metrics:
- Job efficiency
- MPI performance
- Network congestion
- Storage throughput

### Prometheus Metrics

Prometheus collects:
- Slurm metrics
- Node exporter metrics
- FSx metrics
- Custom HPC metrics

## Security

### Network Security

- Private subnets for compute nodes
- Security groups with minimal access
- VPC Flow Logs for monitoring
- AWS Network Firewall for egress filtering

### Access Control

- IAM roles for EC2 instances
- GitHub OIDC for CI/CD authentication
- Secrets Manager for application credentials
- MFA required for all users
- SAML federation support

### Encryption

- EBS encryption with KMS
- S3 encryption with SSE-S3
- FSx encryption at rest
- TLS 1.3 for data in transit

## Cost Optimization

### Instance Strategy

- 70% Spot instances, 30% on-demand
- Automatic instance type selection
- Spot interruption handling
- Reserved Instances for head nodes

### Storage Optimization

- S3 Lifecycle policies
- FSx data compression
- Intelligent-Tiering for S3
- EBS snapshot management

### Network Optimization

- VPC Endpoints to reduce NAT costs
- Direct Connect for predictable pricing
- CloudFront for frequently accessed data

## Troubleshooting

### Common Issues

1. **EFA not available**: Ensure instance type supports EFA
2. **High latency**: Check placement group configuration
3. **Storage performance**: Verify FSx Lustre settings
4. **Job failures**: Check Slurm configuration

### Debug Commands

```bash
# Check cluster status
pcluster describe-cluster --cluster-name hpc-dev --region us-east-2

# SSH to head node
pcluster ssh --cluster-name hpc-dev --region us-east-2

# Check EFA status
fi_info -p efa

# Test MPI communication
mpirun -np 2 --hostfile /opt/parallelcluster/shared/compute_ready_nodes hostname
```

### Logs

- **System logs**: `/var/log/messages`
- **Slurm logs**: `/var/log/slurm/`
- **EFA logs**: `/var/log/efa-setup.log`
- **CloudWatch logs**: `/aws/hpc/hpc-dev/`

## Performance Tuning

### Network Optimization

1. Use cluster placement groups
2. Enable EFA on all compute nodes
3. Configure jumbo frames (9000 MTU)
4. Optimize MPI settings

### Storage Optimization

1. Configure FSx Lustre striping
2. Use appropriate storage types
3. Enable data compression
4. Optimize I/O patterns

### Compute Optimization

1. Disable hyperthreading
2. Pin processes to cores
3. Configure NUMA topology
4. Use appropriate instance types

## Disaster Recovery

### Backup Strategy

- Daily FSx Lustre backups
- EBS snapshot management
- S3 cross-region replication
- Configuration backups

### Failover Procedures

1. **Head node failure**: Automatic replacement
2. **Storage failure**: Cross-AZ replication
3. **Region failure**: Multi-region deployment
4. **Data loss**: Restore from backups

## Support

### Documentation

- [AWS ParallelCluster User Guide](https://docs.aws.amazon.com/parallelcluster/)
- [EFA User Guide](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/efa.html)
- [FSx Lustre User Guide](https://docs.aws.amazon.com/fsx/latest/LustreGuide/)
- [GitHub OIDC Setup Guide](../GITHUB-OIDC-SETUP.md)
- [Infrastructure Summary](../INFRASTRUCTURE-SUMMARY.md)

### Contact

- **HPC Team**: hpc-team@example.com
- **Infrastructure Team**: infra-team@example.com
- **Security Team**: security@example.com

## License

This project is licensed under the MIT License - see the [LICENSE](../LICENSE) file for details.
