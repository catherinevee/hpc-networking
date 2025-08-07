# Azure HPC Networking Examples

This directory contains Azure-equivalent examples for high-performance computing infrastructure, providing similar functionality to the AWS examples but optimized for Azure's HPC services.

## Overview

Azure provides several HPC-optimized services that are equivalent to AWS EFA and FSx for Lustre:

- **InfiniBand**: High-speed interconnect (equivalent to AWS EFA)
- **Azure NetApp Files**: High-performance NFS storage (equivalent to FSx for Lustre)
- **Proximity Placement Groups**: Low-latency networking (equivalent to placement groups)
- **H-Series VMs**: HPC-optimized instances (equivalent to P-series instances)

## Example Types

### 1. Basic Example (`azure-basic/`)

**Use Case**: Simple HPC cluster for development and testing

**Features**:
- 8-node HPC cluster with Standard_HB120rs_v3 instances
- Azure NetApp Files storage (14.4TB)
- Basic monitoring with Application Insights
- InfiniBand networking
- Proximity placement for low latency

**Best For**:
- Development and testing environments
- Small-scale training workloads
- Learning Azure HPC services
- Proof of concept deployments

**Architecture Diagram**: See [`azure-basic/architecture-diagram.md`](azure-basic/architecture-diagram.md) for detailed component relationships.

### 2. Advanced Example (`azure-advanced/`)

**Use Case**: Production HPC cluster with auto-scaling and comprehensive monitoring

**Features**:
- Auto-scaling VM Scale Set (2-16 instances)
- Advanced monitoring and alerting
- Key Vault integration for secrets management
- Enhanced security with private endpoints
- Comprehensive performance tuning
- 90-day log retention

**Best For**:
- Production workloads
- Large-scale training jobs
- Environments requiring auto-scaling
- Organizations with strict security requirements

**Architecture Diagram**: See [`azure-advanced/architecture-diagram.md`](azure-advanced/architecture-diagram.md) for detailed component relationships including auto-scaling and security features.

### 3. Terragrunt Example (`azure-terragrunt/`)

**Use Case**: Production deployments with remote state management

**Features**:
- Remote state management with Azure Storage
- Environment-specific configurations
- Centralized provider management
- Dependency handling
- Consistent tagging and naming

**Best For**:
- Multi-environment deployments
- Teams using Terragrunt
- Production environments requiring state management
- Organizations with multiple Azure subscriptions

**Architecture Diagram**: See [`azure-terragrunt/architecture-diagram.md`](azure-terragrunt/architecture-diagram.md) for detailed Terragrunt configuration and remote state management.

## Architecture Diagrams

For comprehensive visual representations of how Terraform components relate to each other:

- **[Overview Diagram](azure-overview-diagram.md)**: Complete comparison of all three examples
- **[Basic Example](azure-basic/architecture-diagram.md)**: Simple 8-node cluster architecture
- **[Advanced Example](azure-advanced/architecture-diagram.md)**: Production-ready with auto-scaling
- **[Terragrunt Example](azure-terragrunt/architecture-diagram.md)**: Enterprise deployment with remote state

## Azure vs AWS Service Mapping

| AWS Service | Azure Equivalent | Purpose |
|-------------|------------------|---------|
| EFA (Elastic Fabric Adapter) | InfiniBand | High-speed interconnect |
| FSx for Lustre | Azure NetApp Files | High-performance file system |
| P5.48xlarge | Standard_HB120rs_v3 | HPC-optimized compute |
| Placement Groups | Proximity Placement Groups | Low-latency networking |
| CloudWatch | Azure Monitor | Monitoring and alerting |
| IAM Roles | Managed Identities | Identity and access management |
| KMS | Key Vault | Secrets and key management |
| VPC Endpoints | Private Endpoints | Cost optimization |

## Performance Comparison

### Network Performance

| Platform | Interconnect | Bandwidth | Latency |
|----------|--------------|-----------|---------|
| AWS EFA | 3rd Gen EFA | 3,200 Gbps | <50 μs |
| Azure InfiniBand | HDR InfiniBand | 200 Gbps | <50 μs |

### Storage Performance

| Platform | Service | Throughput | Use Case |
|----------|---------|------------|----------|
| AWS FSx for Lustre | 1000 MiB/s per TiB | High-throughput training |
| Azure NetApp Files | 1000 MiB/s per TiB | High-throughput training |

### Compute Performance

| Platform | Instance Type | vCPUs | Memory | GPUs |
|----------|---------------|-------|--------|------|
| AWS P5.48xlarge | 192 | 2TB | 8x H100 |
| Azure Standard_HB120rs_v3 | 120 | 448GB | CPU-only |

## Prerequisites

### Azure Requirements

1. **Azure Subscription**: Active subscription with HPC quota
2. **Azure CLI**: Configured and authenticated
3. **Resource Provider Registration**:
   ```bash
   az provider register --namespace Microsoft.NetApp
   az provider register --namespace Microsoft.Compute
   az provider register --namespace Microsoft.Network
   ```

### Software Requirements

- Terraform 1.12.2
- SSH key pair for VM access
- Terragrunt 0.54.0 (for Terragrunt example)

## Quick Start Guide

### 1. Choose Your Example

Based on your requirements:

- **Development/Testing**: Use `azure-basic/`
- **Production with Auto-scaling**: Use `azure-advanced/`
- **Production with State Management**: Use `azure-terragrunt/`

### 2. Configure Azure Environment

```bash
# Login to Azure
az login

# Set subscription
az account set --subscription <your-subscription-id>

# Verify HPC quota
az vm list-skus --location "East US" --size Standard_HB120rs_v3
```

### 3. Deploy Infrastructure

```bash
# Navigate to your chosen example
cd azure-basic/  # or azure-advanced/ or azure-terragrunt/

# Initialize and deploy
terraform init
terraform plan
terraform apply
```

## Configuration Options

### Instance Types

Azure HPC-optimized instances:

- **Standard_HB120rs_v3**: 120 vCPUs, 448GB RAM, InfiniBand
- **Standard_HB60rs**: 60 vCPUs, 224GB RAM, InfiniBand
- **Standard_HC44rs**: 44 vCPUs, 352GB RAM, InfiniBand

### Storage Options

- **Azure NetApp Files**: NFS storage with Ultra service level
- **Azure Files Premium**: SMB storage for Windows workloads
- **Azure Blob Storage**: Object storage for data lakes

### Networking Options

- **InfiniBand**: High-speed interconnect for MPI applications
- **Accelerated Networking**: Enhanced network performance
- **Private Endpoints**: Secure access to Azure services

## Cost Optimization

### Azure-Specific Optimizations

1. **Reserved Instances**: 1-3 year commitments for cost savings
2. **Spot Instances**: For fault-tolerant workloads
3. **Private Endpoints**: Reduce data transfer costs
4. **Azure Hybrid Benefit**: Use existing licenses

### Cost Comparison

| Component | AWS (Monthly) | Azure (Monthly) |
|-----------|---------------|-----------------|
| P5.48xlarge (8x) | ~$45,000 | N/A (CPU-only) |
| HB120rs_v3 (8x) | N/A | ~$15,000 |
| FSx for Lustre (14.4TB) | ~$2,000 | N/A |
| NetApp Files (14.4TB) | N/A | ~$1,500 |

## Security Considerations

### Azure Security Features

1. **Network Security Groups**: Control network access
2. **Azure Firewall**: Advanced threat protection
3. **Key Vault**: Centralized secrets management
4. **Private Endpoints**: Secure service access
5. **Managed Identities**: Passwordless authentication

### Compliance

- **SOC 1, 2, 3**: Service organization controls
- **ISO 27001**: Information security management
- **FedRAMP**: Federal risk and authorization
- **HIPAA**: Health information privacy

## Monitoring and Observability

### Azure Monitor Integration

- **Application Insights**: Application performance monitoring
- **Log Analytics**: Centralized logging and analysis
- **Metrics**: Real-time performance metrics
- **Alerts**: Automated alerting and notifications

### Custom Monitoring

- **HPC-specific metrics**: InfiniBand performance, MPI statistics
- **Storage metrics**: NetApp Files performance
- **Compute metrics**: CPU, memory, network utilization

## Troubleshooting

### Common Azure Issues

1. **Quota Limits**: Request HPC quota increase
2. **InfiniBand Issues**: Verify instance type and placement
3. **NetApp Files**: Check subnet delegation and service endpoints
4. **Authentication**: Verify managed identities and permissions

### Debug Commands

```bash
# Check Azure resources
az vmss list-instances --resource-group <rg-name> --name <vmss-name>

# Verify NetApp Files
az netappfiles volume show --resource-group <rg-name> --account-name <account> --pool-name <pool> --name <volume>

# Check network connectivity
az network nsg rule list --resource-group <rg-name> --nsg-name <nsg-name>
```

## Migration from AWS

### Key Differences

1. **Instance Types**: Different naming and specifications
2. **Networking**: InfiniBand vs EFA
3. **Storage**: NetApp Files vs FSx for Lustre
4. **Monitoring**: Azure Monitor vs CloudWatch

### Migration Steps

1. **Assessment**: Review current AWS infrastructure
2. **Planning**: Map AWS services to Azure equivalents
3. **Testing**: Deploy test environment using Azure examples
4. **Migration**: Gradually migrate workloads
5. **Optimization**: Tune for Azure-specific features

## Support and Resources

### Documentation

- [Azure HPC Documentation](https://docs.microsoft.com/en-us/azure/virtual-machines/workloads/hpc/)
- [Azure NetApp Files](https://docs.microsoft.com/en-us/azure/azure-netapp-files/)
- [Azure Monitor](https://docs.microsoft.com/en-us/azure/azure-monitor/)

### Community

- [Azure HPC Community](https://techcommunity.microsoft.com/t5/azure-high-performance-computing/bd-p/AzureHighPerformanceComputing)
- [Azure Compute Blog](https://azure.microsoft.com/en-us/blog/tag/azure-compute/)

### Support

- Azure Support Plans
- Microsoft Q&A
- GitHub Issues (for this module)

## Next Steps

1. **Start with Basic Example**: Deploy the basic example to understand Azure HPC services
2. **Evaluate Performance**: Run benchmarks to compare with your current infrastructure
3. **Plan Migration**: Use the examples as templates for your production deployment
4. **Optimize Costs**: Implement cost optimization strategies
5. **Enhance Security**: Add security features based on your requirements

## Contributing

Contributions to improve Azure examples are welcome:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests and documentation
5. Submit a pull request

## License

This project is licensed under the MIT License - see the [LICENSE](../../LICENSE) file for details. 