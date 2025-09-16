# HPC Networking Infrastructure

A production-ready, high-performance computing (HPC) networking infrastructure on AWS with automated CI/CD deployment using Terragrunt and GitHub Actions.

## Overview

This project provides a complete infrastructure-as-code solution for deploying HPC clusters optimized for scientific computing workloads. It includes ultra-low latency networking with Elastic Fabric Adapter (EFA), high-performance parallel storage with FSx Lustre, and automated scaling with AWS ParallelCluster.

## Key Features

- **Ultra-Low Latency Networking**: EFA-enabled instances with <15 microsecond MPI latency
- **High-Performance Storage**: FSx Lustre with 1.2 GB/s per TiB throughput
- **Automated Scaling**: Scale from 0 to 1000 nodes based on job queue depth
- **Cost Optimization**: 70% spot instances with intelligent scaling
- **Secure CI/CD**: GitHub Actions with OIDC authentication
- **Multi-Environment**: Dev, staging, and production configurations
- **Comprehensive Monitoring**: CloudWatch, Grafana, and Prometheus integration

## Architecture

The infrastructure is designed for scientific computing workloads including:
- Computational fluid dynamics (CFD)
- Molecular dynamics simulations
- Weather modeling
- Genomics research
- Machine learning and AI workloads

### Core Components

- **Compute**: AWS ParallelCluster with Slurm scheduler
- **Networking**: EFA-enabled instances with cluster placement groups
- **Storage**: FSx Lustre for parallel file system, S3 for data repository
- **Monitoring**: Real-time performance monitoring and cost tracking
- **Security**: VPC isolation, encryption, and compliance controls

## Quick Start

### Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform >= 1.5.0
- Terragrunt >= 0.50.0
- AWS ParallelCluster >= 3.7.0
- GitHub CLI (optional)

### 1. Clone and Setup

```bash
git clone https://github.com/your-org/hpc-networking.git
cd hpc-networking
```

### 2. Configure GitHub OIDC (Recommended)

```bash
# Linux/macOS
./scripts/setup-github-oidc.sh

# Windows PowerShell
.\scripts\setup-github-oidc.ps1 -GitHubOrg "your-org" -GitHubRepo "hpc-networking"
```

### 3. Deploy Infrastructure

```bash
# Deploy development environment
./scripts/deploy-hpc.sh --environment dev --action apply

# Deploy production environment
./scripts/deploy-hpc.sh --environment production --action apply
```

### 4. Deploy HPC Cluster

```bash
pcluster create-cluster \
  --cluster-name hpc-dev \
  --cluster-configuration cluster-configs/dev.yaml \
  --region us-east-2
```

## Project Structure

```
hpc-networking/
├── infrastructure/              # Terragrunt infrastructure
│   ├── _envcommon/             # Shared configurations
│   ├── modules/                # Custom modules
│   ├── dev/                    # Development environment
│   ├── staging/                # Staging environment
│   └── production/             # Production environment
├── cluster-configs/            # ParallelCluster configurations
│   ├── dev.yaml
│   ├── staging.yaml
│   └── production.yaml
├── scripts/                    # Deployment and setup scripts
│   ├── deploy-hpc.sh
│   ├── setup-github-oidc.sh
│   └── setup-github-oidc.ps1
├── .github/workflows/          # GitHub Actions CI/CD
│   └── hpc-deploy.yml
└── docs/                       # Documentation
    ├── GITHUB-OIDC-SETUP.md
    └── INFRASTRUCTURE-SUMMARY.md
```

## Environments

### Development
- **Capacity**: 100 nodes
- **Instance Types**: c5n.9xlarge, r5n.12xlarge, p3.8xlarge
- **Storage**: 50TB scratch, 10TB persistent
- **Cost**: ~$50,000/month

### Staging
- **Capacity**: 500 nodes
- **Instance Types**: c5n.18xlarge, r5n.24xlarge, p3.16xlarge
- **Storage**: 200TB scratch, 50TB persistent
- **Cost**: ~$150,000/month

### Production
- **Capacity**: 1000 nodes
- **Instance Types**: hpc6a.48xlarge, x2iezn.32xlarge, p4d.24xlarge
- **Storage**: 500TB scratch, 100TB persistent
- **Cost**: ~$200,000/month

## CI/CD Pipeline

The GitHub Actions workflow provides:

- **Automated Deployment**: Deploy on push to main/develop branches
- **Validation**: Network, storage, and compute configuration validation
- **Testing**: MPI communication, EFA functionality, and storage performance
- **Benchmarking**: Network performance tests with OSU micro-benchmarks
- **Cost Analysis**: Monthly cost tracking and optimization

### Security Features

- **OIDC Authentication**: No long-lived AWS credentials
- **Repository-Specific Access**: Limited to specific repository
- **Temporary Credentials**: Short-lived tokens with automatic expiration
- **Audit Trail**: Complete logging of all AWS API calls

## Performance Targets

- **MPI Latency**: < 15 microseconds
- **Network Bandwidth**: 100 Gbps per node
- **Storage Throughput**: > 10 GB/s aggregate
- **Job Startup**: < 30 seconds
- **Scaling Time**: < 5 minutes
- **Availability**: 99.9% for head node, 99% for compute

## Cost Optimization

- **Spot Instances**: 70% spot usage for compute nodes
- **Auto-scaling**: Scale to zero when no jobs
- **Storage Lifecycle**: Automatic tiering to reduce costs
- **Reserved Instances**: For predictable baseline capacity
- **Budget Alerts**: Monitor and control spending

## Security and Compliance

- **Network Isolation**: Private subnets for compute nodes
- **Encryption**: All data encrypted at rest and in transit
- **Access Control**: IAM roles with least privilege
- **Audit Logging**: Complete audit trail of all activities
- **Compliance**: NIST 800-171, HIPAA, and ITAR support

## Monitoring and Observability

- **CloudWatch Dashboards**: Real-time cluster metrics
- **Grafana**: Detailed HPC performance visualization
- **Prometheus**: Custom metrics collection
- **VPC Flow Logs**: Network traffic analysis
- **Cost Tracking**: Per-research-group cost attribution

## Documentation

- [Infrastructure Guide](infrastructure/README.md) - Detailed infrastructure documentation
- [GitHub OIDC Setup](GITHUB-OIDC-SETUP.md) - Secure CI/CD configuration
- [Infrastructure Summary](INFRASTRUCTURE-SUMMARY.md) - Implementation overview

## Support

For issues and questions:
- Check the troubleshooting section in the infrastructure README
- Review the GitHub OIDC setup guide
- Consult AWS documentation for specific services

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
