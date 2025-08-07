# Basic Azure HPC Networking Example

This example demonstrates a basic Azure HPC (High-Performance Computing) infrastructure setup optimized for machine learning workloads using Azure's HPC-optimized services.

## Overview

This example creates a simple 8-node HPC cluster with the following components:

- **Virtual Network**: Tiered subnet architecture for compute, storage, and endpoints
- **VM Scale Set**: HPC-optimized instances (Standard_HB120rs_v3) with InfiniBand support
- **Azure NetApp Files**: High-performance NFS storage (14.4TB)
- **Proximity Placement Group**: Low-latency networking between instances
- **Network Security Groups**: Optimized for HPC communication
- **Monitoring**: Application Insights and Log Analytics integration

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Virtual Network (10.0.0.0/16)               │
├─────────────────────────────────────────────────────────────────┤
│  Compute Subnet (10.0.10.0/22)                                │
│  ├── VM Scale Set (8x Standard_HB120rs_v3)                    │
│  ├── Proximity Placement Group                                │
│  └── InfiniBand Network                                       │
├─────────────────────────────────────────────────────────────────┤
│  Storage Subnet (10.0.20.0/24)                                │
│  ├── Azure NetApp Files (14.4TB)                              │
│  └── NFS v4.1 Protocol                                        │
├─────────────────────────────────────────────────────────────────┤
│  Endpoints Subnet (10.0.30.0/24)                              │
│  └── Private Endpoints (future use)                           │
└─────────────────────────────────────────────────────────────────┘
```

## Prerequisites

- Terraform 1.12.2
- Azure CLI configured
- SSH key pair for VM access
- Azure subscription with HPC quota

## Quick Start

### 1. Configure Azure CLI

```bash
# Login to Azure
az login

# Set subscription
az account set --subscription <your-subscription-id>
```

### 2. Update Configuration

Edit `main.tf` and update the following:

```hcl
# Update SSH key path
admin_ssh_key {
  username   = "azureuser"
  public_key = file("~/.ssh/id_rsa.pub") # Update this path
}
```

### 3. Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Plan deployment
terraform plan

# Apply configuration
terraform apply
```

### 4. Access Your HPC Cluster

```bash
# Get VM Scale Set information
az vmss list-instances --resource-group hpc-networking-rg --name hpc-vmss

# SSH to an instance (replace with actual IP)
ssh azureuser@<instance-ip>
```

## Key Features

### HPC-Optimized Instances

- **Standard_HB120rs_v3**: 120 vCPUs, 448 GB RAM, InfiniBand support
- **InfiniBand**: High-speed interconnect for MPI applications
- **Proximity Placement**: Low-latency networking between instances

### High-Performance Storage

- **Azure NetApp Files**: Enterprise-grade NFS storage
- **Ultra Service Level**: 1000 MiB/s per TiB throughput
- **NFS v4.1**: Optimized for HPC workloads

### Network Optimization

- **Network Security Groups**: Optimized for HPC communication
- **InfiniBand Rules**: Allow all InfiniBand traffic within compute subnet
- **SSH Access**: Secure access from VNet

### Monitoring Integration

- **Application Insights**: Application performance monitoring
- **Log Analytics**: Centralized logging and analysis
- **Custom Scripts**: HPC-specific monitoring and benchmarking

## Performance Specifications

| Component | Specification |
|-----------|---------------|
| Instance Type | Standard_HB120rs_v3 |
| vCPUs | 120 |
| Memory | 448 GB |
| InfiniBand | 200 Gbps |
| Storage | 14.4TB (1000 MiB/s per TiB) |
| Network Latency | <50 μs (proximity placement) |

## Usage Examples

### Running MPI Applications

```bash
# SSH to an instance
ssh azureuser@<instance-ip>

# Test MPI communication
mpirun -np 8 --hostfile hostfile hostname

# Run HPC benchmark
/usr/local/bin/hpc-benchmark.sh
```

### Accessing Storage

```bash
# Storage is automatically mounted at /mnt/netapp
ls -la /mnt/netapp/

# Create directories for your workload
mkdir -p /mnt/netapp/data
mkdir -p /mnt/netapp/models
mkdir -p /mnt/netapp/logs
```

### Monitoring Performance

```bash
# Check system resources
htop
iotop

# Monitor InfiniBand
ibstat
ibv_devinfo

# View performance logs
tail -f /var/log/hpc-monitor.log
```

## Cost Optimization

- **Proximity Placement Group**: Reduces network latency and costs
- **Azure NetApp Files**: Pay only for used storage
- **VM Scale Set**: Efficient resource utilization
- **Monitoring**: 30-day log retention (configurable)

## Security Features

- **Network Security Groups**: Restrictive access policies
- **SSH Key Authentication**: Secure VM access
- **Private Subnets**: Isolated compute and storage networks
- **Managed Identity**: Secure Azure service access

## Troubleshooting

### Common Issues

1. **InfiniBand Not Working**
   ```bash
   # Check InfiniBand status
   ibstat
   ibv_devinfo
   
   # Verify network interface
   ip link show | grep ib
   ```

2. **Storage Mount Issues**
   ```bash
   # Check NetApp Files status
   az netappfiles volume show --resource-group hpc-networking-rg --account-name hpc-netapp-account --pool-name hpc-netapp-pool --name hpc-netapp-volume
   
   # Verify mount point
   df -h /mnt/netapp
   ```

3. **Performance Issues**
   ```bash
   # Run performance benchmark
   /usr/local/bin/hpc-benchmark.sh
   
   # Check system resources
   htop
   iotop
   ```

### Debug Commands

```bash
# System information
/usr/local/bin/system-info.sh

# Network diagnostics
iperf3 -c <target_ip>
netperf -H <target_ip>

# InfiniBand diagnostics
ib_write_bw -d mlx5_0 -s 65536 -n 1000
ib_read_bw -d mlx5_0 -s 65536 -n 1000
```

## Cleanup

```bash
# Destroy infrastructure
terraform destroy

# Verify cleanup
az group show --name hpc-networking-rg
```

## Next Steps

- Explore the [Advanced Example](../azure-advanced/) for auto-scaling and enhanced monitoring
- Check the [Terragrunt Example](../azure-terragrunt/) for production deployment patterns
- Review the main module documentation for additional configuration options

## Support

For issues with this example:
- Check the troubleshooting section above
- Review Azure Monitor logs for diagnostics
- Ensure all prerequisites are met
- Verify Azure subscription quotas for HPC instances 