# HPC Networking Examples

This directory contains comprehensive examples for deploying high-performance computing infrastructure using the HPC Networking Terraform module.

## Examples Overview

### AWS Examples

- **[Basic Training Cluster](basic/)**: Simple 8-node training cluster with EFA and FSx for Lustre
- **[Advanced Auto Scaling](advanced/)**: Production-ready cluster with auto-scaling and enhanced monitoring
- **[Multi-Region Setup](multi-region/)**: Cross-region deployment for disaster recovery
- **[Terragrunt Integration](terragrunt/)**: Enterprise deployment with remote state management

### Azure Examples

- **[Basic HPC Cluster](azure-basic/)**: Simple 8-node HPC cluster with InfiniBand and Azure NetApp Files
- **[Advanced Auto-Scaling](azure-advanced/)**: Production HPC cluster with auto-scaling and comprehensive monitoring
- **[Terragrunt Integration](azure-terragrunt/)**: Azure HPC deployment with remote state management

For detailed Azure examples documentation, see [azure-README.md](azure-README.md).

## Architecture Diagrams

### AWS Architecture Diagrams

Each AWS example includes detailed architecture diagrams showing Terraform component relationships:

- **[Basic Example Architecture](basic/architecture-diagram.md)**: Simple cluster with EFA and FSx for Lustre
- **[Advanced Example Architecture](advanced/architecture-diagram.md)**: Auto-scaling cluster with enhanced monitoring
- **[Multi-Region Architecture](multi-region/architecture-diagram.md)**: Cross-region deployment patterns
- **[Terragrunt Architecture](terragrunt/architecture-diagram.md)**: Remote state management and team collaboration

### Azure Architecture Diagrams

Comprehensive Azure architecture diagrams showing component relationships:

- **[Azure Overview](azure-overview-diagram.md)**: Complete comparison of all Azure examples
- **[Basic Azure Architecture](azure-basic/architecture-diagram.md)**: Simple 8-node cluster with InfiniBand
- **[Advanced Azure Architecture](azure-advanced/architecture-diagram.md)**: Production-ready with auto-scaling and security
- **[Terragrunt Azure Architecture](azure-terragrunt/architecture-diagram.md)**: Enterprise deployment with remote state

## Key Features by Example

| Feature | AWS Basic | AWS Advanced | AWS Multi-Region | AWS Terragrunt | Azure Basic | Azure Advanced | Azure Terragrunt |
|---------|-----------|--------------|------------------|----------------|-------------|----------------|------------------|
| **Compute** | 8 × P5.48xlarge | 2-16 × P5.48xlarge | Multi-region | Auto-scaling | 8 × HB120rs_v3 | 2-16 × HB120rs_v3 | Auto-scaling |
| **Networking** | EFA | EFA + Enhanced | Cross-region | EFA | InfiniBand | InfiniBand | InfiniBand |
| **Storage** | FSx for Lustre | FSx for Lustre | Multi-region | FSx for Lustre | NetApp Files | NetApp Files | NetApp Files |
| **Auto-scaling** | ❌ | ✅ | ❌ | ✅ | ❌ | ✅ | ✅ |
| **Monitoring** | CloudWatch | Enhanced | Multi-region | Enhanced | App Insights | Enhanced | Enhanced |
| **Security** | Basic | Enhanced | Enhanced | Enhanced | Basic | Key Vault | Key Vault |
| **State Management** | Local | Local | Local | Remote | Local | Local | Remote |
| **Team Collaboration** | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ✅ |

## Quick Start

### AWS Examples

```bash
# Basic example
cd examples/basic
terraform init
terraform plan
terraform apply

# Advanced example
cd examples/advanced
terraform init
terraform plan
terraform apply

# Terragrunt example
cd examples/terragrunt
terragrunt init
terragrunt plan
terragrunt apply
```

### Azure Examples

```bash
# Basic example
cd examples/azure-basic
terraform init
terraform plan
terraform apply

# Advanced example
cd examples/azure-advanced
terraform init
terraform plan
terraform apply

# Terragrunt example
cd examples/azure-terragrunt
terragrunt init
terragrunt plan
terragrunt apply
```

## Prerequisites

### AWS Examples
- Terraform 1.12.2+
- AWS CLI configured
- Appropriate AWS permissions
- Existing VPC (for basic/advanced examples)

### Azure Examples
- Terraform 1.12.2+
- Azure CLI configured
- Appropriate Azure permissions
- Azure Storage Account (for Terragrunt example)

## Cost Considerations

### AWS Examples
- **Basic**: ~$15K-20K/month (8 × P5.48xlarge)
- **Advanced**: ~$10K-40K/month (2-16 × P5.48xlarge)
- **Multi-Region**: ~$30K-80K/month (multi-region deployment)
- **Terragrunt**: Same as Advanced + storage costs

### Azure Examples
- **Basic**: ~$15K-20K/month (8 × HB120rs_v3)
- **Advanced**: ~$10K-40K/month (2-16 × HB120rs_v3)
- **Terragrunt**: Same as Advanced + Azure Storage costs

## Performance Characteristics

| Platform | Network Latency | Storage Throughput | Auto-scaling | High Availability |
|----------|----------------|-------------------|--------------|-------------------|
| **AWS Basic** | <50 μs | 14.4 GB/s | ❌ | Standard |
| **AWS Advanced** | <50 μs | 14.4 GB/s | ✅ | High |
| **AWS Multi-Region** | <50 μs | 14.4 GB/s | ❌ | Very High |
| **AWS Terragrunt** | <50 μs | 14.4 GB/s | ✅ | High |
| **Azure Basic** | <50 μs | 28.8 GB/s | ❌ | Standard |
| **Azure Advanced** | <50 μs | 56 GB/s | ✅ | High |
| **Azure Terragrunt** | <50 μs | 28.8 GB/s | ✅ | High |

## Use Case Recommendations

### Development & Testing
- **AWS Basic** or **Azure Basic**
- Quick setup for development
- Cost-effective for learning

### Production Workloads
- **AWS Advanced** or **Azure Advanced**
- Auto-scaling capabilities
- Enhanced security and monitoring

### Enterprise Deployments
- **AWS Terragrunt** or **Azure Terragrunt**
- Team collaboration
- Remote state management
- Environment management

### Multi-Region Requirements
- **AWS Multi-Region**
- Disaster recovery
- Geographic distribution

## Migration Paths

### AWS to Azure Migration
```
AWS Basic → Azure Basic
AWS Advanced → Azure Advanced
AWS Terragrunt → Azure Terragrunt
```

### Complexity Progression
```
Basic → Advanced → Terragrunt
(Add auto-scaling) (Add team collaboration)
```

## Support

For questions and support:
- Check the architecture diagrams for component relationships
- Review the individual example README files
- Consult the main module documentation
- Create an issue in the repository

## Contributing

When adding new examples:
1. Follow the existing directory structure
2. Include comprehensive architecture diagrams
3. Document all components and relationships
4. Provide clear use case recommendations
5. Include cost and performance information 