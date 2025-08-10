# High-Performance Networking Terraform Module

A production-ready Terraform module for deploying high-performance computing (HPC) infrastructure optimized for AI/ML workloads with AWS EFA (Elastic Fabric Adapter), GPUDirect, and distributed training capabilities.

## Architecture Overview

### High-Level Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                                AWS Cloud Infrastructure                              │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                     │
│  ┌─────────────────────────────────────────────────────────────────────────────┐   │
│  │                              VPC (10.0.0.0/16)                             │   │
│  ├─────────────────────────────────────────────────────────────────────────────┤   │
│  │                                                                             │   │
│  │  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────────────┐ │   │
│  │  │   Public Tier   │    │  Compute Tier   │    │      Storage Tier       │ │   │
│  │  │                 │    │                 │    │                         │ │   │
│  │  │ ┌─────────────┐ │    │ ┌─────────────┐ │    │ ┌─────────────────────┐ │ │   │
│  │  │ │Internet GW  │ │    │ │EFA Instances│ │    │ │   FSx for Lustre    │ │ │   │
│  │  │ │             │ │    │ │(p5.48xlarge)│ │    │ │   (14.4TB+ Storage) │ │ │   │
│  │  │ └─────────────┘ │    │ └─────────────┘ │    │ └─────────────────────┘ │ │   │
│  │  │                 │    │                 │    │                         │ │   │
│  │  │ ┌─────────────┐ │    │ ┌─────────────┐ │    │ ┌─────────────────────┐ │ │   │
│  │  │ │NAT Gateways │ │    │ │Placement    │ │    │ │   S3 Data Repo      │ │ │   │
│  │  │ │             │ │    │ │Groups       │ │    │ │   (Versioned)       │ │ │   │
│  │  │ └─────────────┘ │    │ └─────────────┘ │    │ └─────────────────────┘ │ │   │
│  │  │                 │    │                 │    │                         │ │   │
│  │  │ ┌─────────────┐ │    │ ┌─────────────┐ │    │ ┌─────────────────────┐ │ │   │
│  │  │ │Load         │ │    │ │Auto Scaling │ │    │ │   KMS Encryption    │ │ │   │
│  │  │ │Balancers    │ │    │ │Groups       │ │    │ │   Keys              │ │ │   │
│  │  │ └─────────────┘ │    │ └─────────────┘ │    │ └─────────────────────┘ │ │   │
│  │  └─────────────────┘    └─────────────────┘    └─────────────────────────┘ │   │
│  │                                                                             │   │
│  │  ┌─────────────────────────────────────────────────────────────────────────┐ │   │
│  │  │                        VPC Endpoints Tier                               │ │   │
│  │  │                                                                         │ │   │
│  │  │ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐ │ │   │
│  │  │ │   S3    │ │DynamoDB │ │SageMaker│ │   FSx   │ │   ECR   │ │CloudWatch│ │ │   │
│  │  │ │Endpoint │ │Endpoint │ │Endpoint │ │Endpoint │ │Endpoint │ │ Endpoint │ │ │   │
│  │  │ └─────────┘ └─────────┘ └─────────┘ └─────────┘ └─────────┘ └─────────┘ │ │   │
│  │  └─────────────────────────────────────────────────────────────────────────┘ │   │
│  └─────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                     │
│  ┌─────────────────────────────────────────────────────────────────────────────┐   │
│  │                           Security & Monitoring                             │   │
│  ├─────────────────────────────────────────────────────────────────────────────┤   │
│  │                                                                             │   │
│  │ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐           │   │
│  │ │IAM Roles &  │ │Security     │ │CloudWatch   │ │KMS          │           │   │
│  │ │Policies     │ │Groups       │ │Monitoring   │ │Encryption   │           │   │
│  │ │(Least       │ │(EFA, FSx,   │ │& Alarms     │ │(At Rest &   │           │   │
│  │ │Privilege)   │ │Endpoints)   │ │             │ │In Transit)  │           │   │
│  │ └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘           │   │
│  └─────────────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

### Network Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                              Network Traffic Flow                                   │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                     │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐         │
│  │   Internet  │    │  Internet   │    │   NAT       │    │   Private   │         │
│  │   Gateway   │    │   Gateway   │    │  Gateway    │    │   Compute   │         │
│  │             │    │             │    │             │    │   Subnets   │         │
│  │  (Public)   │    │  (Public)   │    │  (Public)   │    │             │         │
│  └─────┬───────┘    └─────┬───────┘    └─────┬───────┘    └─────┬───────┘         │
│        │                  │                  │                  │                 │
│        │                  │                  │                  │                 │
│        ▼                  ▼                  ▼                  ▼                 │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐         │
│  │   Public    │    │   Public    │    │   Private   │    │   EFA       │         │
│  │   Subnets   │    │   Subnets   │    │   Compute   │    │ Instances   │         │
│  │             │    │             │    │   Subnets   │    │             │         │
│  │10.0.1.0/24  │    │10.0.2.0/24  │    │10.0.10.0/22│    │(p5.48xlarge)│         │
│  │10.0.2.0/24  │    │             │    │10.0.14.0/22│    │             │         │
│  └─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘         │
│        │                  │                  │                  │                 │
│        │                  │                  │                  │                 │
│        └──────────────────┼──────────────────┼──────────────────┘                 │
│                           │                  │                                    │
│                           ▼                  ▼                                    │
│                  ┌─────────────┐    ┌─────────────┐                              │
│                  │   Private   │    │   Private   │                              │
│                  │   Storage   │    │  Endpoint   │                              │
│                  │   Subnets   │    │   Subnets   │                              │
│                  │             │    │             │                              │
│                  │10.0.20.0/24 │    │10.0.30.0/24 │                              │
│                  │10.0.21.0/24 │    │10.0.31.0/24 │                              │
│                  └─────┬───────┘    └─────┬───────┘                              │
│                        │                  │                                      │
│                        ▼                  ▼                                      │
│                  ┌─────────────┐    ┌─────────────┐                              │
│                  │   FSx for   │    │   VPC       │                              │
│                  │   Lustre    │    │  Endpoints  │                              │
│                  │             │    │             │                              │
│                  │(High Perf)  │    │(S3, ECR,    │                              │
│                  │             │    │ SageMaker)  │                              │
│                  └─────────────┘    └─────────────┘                              │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

### Security Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                              Security Architecture                                  │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                     │
│  ┌─────────────────────────────────────────────────────────────────────────────┐   │
│  │                           IAM Security Layer                                │   │
│  ├─────────────────────────────────────────────────────────────────────────────┤   │
│  │                                                                             │   │
│  │  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐ │   │
│  │  │   EC2 Role  │    │CloudWatch   │    │   KMS Key   │    │   Instance  │ │   │
│  │  │             │    │   Role      │    │   Policy    │    │   Profile   │ │   │
│  │  │• Describe   │    │• PutMetrics │    │• Encrypt    │    │• Attached   │ │   │
│  │  │  Instances  │    │• CreateLogs │    │• Decrypt    │    │  to EC2     │ │   │
│  │  │• S3 Access  │    │• ListMetrics│    │• Generate   │    │  Instances  │ │   │
│  │  │• ECR Access │    │             │    │  DataKeys   │    │             │ │   │
│  │  │(Least Priv) │    │(Restricted) │    │(Tag-based)  │    │(Secure)     │ │   │
│  │  └─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘ │   │
│  └─────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                     │
│  ┌─────────────────────────────────────────────────────────────────────────────┐   │
│  │                        Network Security Layer                                │   │
│  ├─────────────────────────────────────────────────────────────────────────────┤   │
│  │                                                                             │   │
│  │  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐ │   │
│  │  │   EFA SG    │    │   FSx SG    │    │ Endpoint SG │    │   ALB SG    │ │   │
│  │  │             │    │             │    │             │    │             │ │   │
│  │  │• Port 18515 │    │• Port 988   │    │• Port 443   │    │• Port 80    │ │   │
│  │  │• Port 18516 │    │• Port 1021- │    │(HTTPS only) │    │• Port 443   │ │   │
│  │  │• Port 29500 │    │  1023       │    │             │    │(HTTPS only) │ │   │
│  │  │• Port 29599 │    │• Port 2049  │    │             │    │             │ │   │
│  │  │(NCCL)       │    │(Lustre)     │    │             │    │             │ │   │
│  │  └─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘ │   │
│  └─────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                     │
│  ┌─────────────────────────────────────────────────────────────────────────────┐   │
│  │                        Data Security Layer                                   │   │
│  ├─────────────────────────────────────────────────────────────────────────────┤   │
│  │                                                                             │   │
│  │  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐ │   │
│  │  │   KMS Key   │    │   S3 Bucket │    │   EBS       │    │   FSx       │ │   │
│  │  │             │    │             │    │   Volumes   │    │   Lustre    │ │   │
│  │  │• AES-256    │    │• Versioning │    │             │    │             │ │   │
│  │  │• Key        │    │• Encryption │    │• GP3        │    │• Encryption │ │   │
│  │  │  Rotation   │    │• Public     │    │• Encryption │    │• High Perf  │ │   │
│  │  │• Tag-based  │    │  Access     │    │• KMS Key    │    │• GPUDirect  │ │   │
│  │  │  Access     │    │  Blocked    │    │             │    │  Storage    │ │   │
│  │  └─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘ │   │
│  └─────────────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

### Performance Optimization Diagram

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                           Performance Optimization                                  │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                     │
│  ┌─────────────────────────────────────────────────────────────────────────────┐   │
│  │                           Network Optimization                               │   │
│  ├─────────────────────────────────────────────────────────────────────────────┤   │
│  │                                                                             │   │
│  │  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐ │   │
│  │  │   EFA       │    │ Jumbo Frames│    │   SR-IOV    │    │   NUMA      │ │   │
│  │  │             │    │             │    │             │    │             │ │   │
│  │  │• 3rd Gen    │    │• MTU 9001   │    │• Enhanced   │    │• CPU Affinity│ │   │
│  │  │• 3,200 Gbps │    │• High BW    │    │  Networking │    │• Memory     │ │   │
│  │  │• Low Latency│    │• Reduced    │    │• Direct     │    │• Interrupt  │ │   │
│  │  │• GPUDirect  │    │  Overhead   │    │  Hardware   │    │• Coalescing │ │   │
│  │  │  RDMA       │    │             │    │  Access     │    │             │ │   │
│  │  └─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘ │   │
│  └─────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                     │
│  ┌─────────────────────────────────────────────────────────────────────────────┐   │
│  │                           Storage Optimization                               │   │
│  ├─────────────────────────────────────────────────────────────────────────────┤   │
│  │                                                                             │   │
│  │  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐ │   │
│  │  │   FSx       │    │   S3 Data   │    │   EBS GP3   │    │   Data      │ │   │
│  │  │   Lustre    │    │   Repo      │    │   Volumes   │    │   Flow      │ │   │
│  │  │             │    │             │    │             │    │             │ │   │
│  │  │• 1000 MiB/s │    │• Auto Import│    │• 3000 IOPS  │    │• S3 → FSx   │ │   │
│  │  │  per TiB    │    │• Auto Export│    │• 125 MB/s   │    │• FSx → S3   │ │   │
│  │  │• GPUDirect  │    │• Versioning │    │• Encryption │    │• Lustre     │ │   │
│  │  │  Storage    │    │• Encryption │    │• KMS Key    │    │  Protocol   │ │   │
│  │  └─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘ │   │
│  └─────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                     │
│  ┌─────────────────────────────────────────────────────────────────────────────┐   │
│  │                           Compute Optimization                                │   │
│  ├─────────────────────────────────────────────────────────────────────────────┤   │
│  │                                                                             │   │
│  │  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐ │   │
│  │  │   P5        │    │ Placement   │    │ Auto Scaling│    │   Launch    │ │   │
│  │  │ Instances   │    │   Groups    │    │   Groups    │    │  Templates  │ │   │
│  │  │             │    │             │    │             │    │             │ │   │
│  │  │• H100 GPUs  │    │• Cluster    │    │• CPU-based  │    │• Optimized  │ │   │
│  │  │• 8 GPUs     │    │  Strategy   │    │  Scaling    │    │  AMI        │ │   │
│  │  │• 3,200 Gbps │    │• Low Latency│    │• Health     │    │• EFA Config │ │   │
│  │  │• EFA Ready  │    │• Fault      │    │  Checks     │    │• Monitoring │ │   │
│  │  │             │    │  Isolation  │    │             │    │             │ │   │
│  │  └─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘ │   │
│  └─────────────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

### Resource Protection Diagram

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                           Resource Protection Strategy                              │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                     │
│  ┌─────────────────────────────────────────────────────────────────────────────┐   │
│  │                        Critical Resources                                    │   │
│  ├─────────────────────────────────────────────────────────────────────────────┤   │
│  │                                                                             │   │
│  │  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐ │   │
│  │  │   FSx for   │    │   S3 Data   │    │   KMS       │    │   IAM       │ │   │
│  │  │   Lustre    │    │ Repository  │    │   Keys      │    │   Roles     │ │   │
│  │  │             │    │             │    │             │    │             │ │   │
│  │  │• prevent_   │    │• prevent_   │    │• prevent_   │    │• prevent_   │ │   │
│  │  │  destroy    │    │  destroy    │    │  destroy    │    │  destroy    │ │   │
│  │  │• create_    │    │• versioning │    │• key        │    │• least      │ │   │
│  │  │  before_    │    │• encryption │    │  rotation   │    │  privilege  │ │   │
│  │  │  destroy    │    │• public     │    │• tag-based  │    │• specific   │ │   │
│  │  │• backup     │    │  access     │    │  access     │    │  ARNs       │ │   │
│  │  │  strategy   │    │  blocked    │    │             │    │             │ │   │
│  │  └─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘ │   │
│  └─────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                     │
│  ┌─────────────────────────────────────────────────────────────────────────────┐   │
│  │                        State Management                                      │   │
│  ├─────────────────────────────────────────────────────────────────────────────┤   │
│  │                                                                             │   │
│  │  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐ │   │
│  │  │   For_each  │    │   Stable    │    │   Resource  │    │   Backup    │ │   │
│  │  │   Resources │    │   Addressing│    │   Tags      │    │   Strategy  │ │   │
│  │  │             │    │             │    │             │    │             │ │   │
│  │  │• Network    │    │• Consistent │    │• Project    │    │• State      │ │   │
│  │  │  Interfaces │    │  Names      │    │  Tags       │    │  Files      │ │   │
│  │  │• EC2        │    │• Environment│    │• Environment│    │• S3         │ │   │
│  │  │  Instances  │    │  Tags       │    │  Tags       │    │  Backend    │ │   │
│  │  │• Auto       │    │• Resource   │    │• Cost       │    │• DynamoDB   │ │   │
│  │  │  Scaling    │    │  Type Tags  │    │  Center     │    │  Locking    │ │   │
│  │  └─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘ │   │
│  └─────────────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

## Features

- **EFA Support**: Full Elastic Fabric Adapter support with up to 3,200 Gbps bandwidth
- **GPUDirect**: GPU Direct RDMA for optimal GPU-to-GPU communication
- **FSx for Lustre**: High-performance file system with GPUDirect Storage
- **Auto Scaling**: Intelligent scaling based on CPU utilization
- **Cost Optimization**: VPC endpoints, spot instances, and placement optimization
- **Monitoring**: Complete CloudWatch monitoring and alerting
- **Security**: IAM roles, KMS encryption, and security groups
- **Performance Tuning**: Automated network and system optimization

## Performance Specifications

### Instance Type Performance

| Instance Type | EFA Generation | Bandwidth | GPU Count | GPU Type | Use Case |
|---------------|----------------|-----------|-----------|----------|----------|
| p5.48xlarge   | 3rd Gen        | 3,200 Gbps| 8         | H100     | Large-scale training |
| p5.24xlarge   | 3rd Gen        | 1,600 Gbps| 4         | H100     | Medium-scale training |
| p5.12xlarge   | 3rd Gen        | 800 Gbps  | 2         | H100     | Small-scale training |
| p4d.24xlarge  | 2nd Gen        | 400 Gbps  | 8         | A100     | Production training |
| p4de.24xlarge | 2nd Gen        | 400 Gbps  | 8         | A100     | Training + NVMe |
| g5.48xlarge   | 1st Gen        | 100 Gbps  | 8         | Various  | Inference/Development |

### Network Performance

| Placement Strategy | Expected Latency | Use Case |
|-------------------|------------------|----------|
| cluster           | <50 μs          | Low-latency training |
| partition         | ~200 μs         | Large-scale clusters |
| spread            | ~500 μs         | Fault isolation |

## Prerequisites

- Terraform 1.12.2
- AWS CLI configured
- Existing VPC with sufficient IP space
- Appropriate AWS permissions

## Quick Start

### Basic Usage

```hcl
module "hpc_networking" {
  source = "./hpc-networking"

  # Required variables
  vpc_id = "vpc-12345678"
  
  # Instance configuration
  instance_type = "p5.48xlarge"
  instance_count = 8
  
  # Networking
  enable_efa = true
  enable_gdr = true
  placement_strategy = "cluster"
  
  # Storage
  enable_fsx_lustre = true
  fsx_storage_capacity = 14400 # 14.4TB
  
  # Cost optimization
  enable_vpc_endpoints = true
  allow_spot_instances = false
  
  # Monitoring
  enable_cloudwatch = true
  
  # Tags
  project_name = "ml-training"
  environment = "prod"
  
  tags = {
    Owner       = "ML Team"
    CostCenter  = "AI-Infrastructure"
    DataClass   = "Confidential"
  }
}
```

### Advanced Usage with Auto Scaling

```hcl
module "hpc_networking" {
  source = "./hpc-networking"

  vpc_id = "vpc-12345678"
  
  # Auto scaling configuration
  enable_auto_scaling = true
  min_size = 2
  max_size = 16
  desired_capacity = 8
  
  # Performance optimization
  instance_type = "p5.48xlarge"
  enable_efa = true
  enable_gdr = true
  placement_strategy = "cluster"
  
  # Advanced networking
  enable_jumbo_frames = true
  enable_sriov = true
  numa_optimization = true
  
  # Storage with data repository
  enable_fsx_lustre = true
  fsx_storage_capacity = 28800 # 28.8TB
  fsx_deployment_type = "PERSISTENT_2"
  
  # Security
  enable_encryption = true
  allowed_cidr_blocks = ["10.0.0.0/16", "192.168.1.0/24"]
  
  # Monitoring and alerting
  enable_cloudwatch = true
  cloudwatch_retention_days = 90
  
  tags = {
    Project     = "BERT-Training"
    Environment = "production"
    Owner       = "AI-Research"
  }
}
```

## Input Variables

### Required Variables

| Name | Description | Type | Default |
|------|-------------|------|---------|
| vpc_id | Existing VPC ID | string | - |

### Optional Variables

#### Instance Configuration
| Name | Description | Type | Default |
|------|-------------|------|---------|
| instance_type | EC2 instance type | string | "p5.48xlarge" |
| instance_count | Number of instances | number | 8 |
| enable_auto_scaling | Enable auto scaling | bool | false |
| min_size | Minimum ASG size | number | 1 |
| max_size | Maximum ASG size | number | 64 |
| desired_capacity | Desired ASG capacity | number | 8 |

#### Networking
| Name | Description | Type | Default |
|------|-------------|------|---------|
| enable_efa | Enable EFA | bool | true |
| enable_gdr | Enable GPUDirect | bool | true |
| placement_strategy | Placement group strategy | string | "cluster" |
| enable_jumbo_frames | Enable jumbo frames | bool | true |
| enable_sriov | Enable SR-IOV | bool | true |
| numa_optimization | Enable NUMA optimization | bool | true |

#### Storage
| Name | Description | Type | Default |
|------|-------------|------|---------|
| enable_fsx_lustre | Enable FSx for Lustre | bool | true |
| fsx_storage_capacity | Storage capacity (GB) | number | 14400 |
| fsx_deployment_type | Deployment type | string | "PERSISTENT_2" |

#### Security
| Name | Description | Type | Default |
|------|-------------|------|---------|
| enable_encryption | Enable encryption | bool | true |
| allowed_cidr_blocks | Allowed CIDR blocks | list(string) | ["10.0.0.0/16"] |
| key_name | SSH key pair name | string | "" |

#### Cost Optimization
| Name | Description | Type | Default |
|------|-------------|------|---------|
| enable_vpc_endpoints | Enable VPC endpoints | bool | true |
| allow_spot_instances | Allow spot instances | bool | false |
| spot_max_price | Spot max price (%) | string | "90" |

#### Monitoring
| Name | Description | Type | Default |
|------|-------------|------|---------|
| enable_cloudwatch | Enable CloudWatch | bool | true |
| cloudwatch_retention_days | Log retention (days) | number | 30 |

## Outputs

### Network Information
- `efa_network_interfaces`: EFA network interface details
- `hpc_instances`: Instance information
- `autoscaling_group`: Auto scaling group details
- `placement_group`: Placement group information
- `network_performance_metrics`: Expected performance metrics

### Infrastructure
- `subnets`: Subnet information by tier
- `route_tables`: Route table details
- `security_groups`: Security group information
- `vpc_endpoints`: VPC endpoint details
- `nat_gateways`: NAT gateway information

### Storage
- `fsx_lustre`: FSx for Lustre details
- `s3_data_repository`: S3 data repository information

### Security & Monitoring
- `iam_roles`: IAM roles and policies
- `kms_encryption`: KMS encryption details
- `cloudwatch_monitoring`: CloudWatch monitoring setup

### Performance
- `efa_environment_variables`: EFA optimization variables
- `network_tuning_parameters`: Network tuning settings
- `performance_benchmarks`: Expected performance benchmarks

## Performance Optimization

### EFA Environment Variables

The module automatically configures optimal EFA environment variables:

```bash
# EFA optimization
FI_EFA_FORK_SAFE=1
FI_EFA_USE_DEVICE_RDMA=1
NCCL_NET_GDR_LEVEL=2
NCCL_ALGO=Ring
NCCL_DEBUG=INFO

# Performance tuning
OMP_NUM_THREADS=1
MKL_NUM_THREADS=1
```

### Network Tuning

Automatic network optimization includes:

- TCP buffer optimization
- Jumbo frames (9001 MTU)
- NUMA affinity
- Interrupt coalescing
- CPU governor optimization

### Storage Optimization

- FSx for Lustre with 1000 MiB/s per TiB
- S3 data repository integration
- Progressive file layout
- GPUDirect Storage support

## Cost Optimization

### VPC Endpoints

Reduces NAT gateway costs by using VPC endpoints for:
- S3, DynamoDB
- SageMaker API/Runtime
- FSx, EFS
- EC2, ECR
- CloudWatch Logs/Monitoring

### Spot Instances

Enable spot instances for non-production workloads:
```hcl
allow_spot_instances = true
spot_max_price = "80" # 80% of on-demand
```

### Auto Scaling

Intelligent scaling based on CPU utilization:
```hcl
enable_auto_scaling = true
min_size = 2
max_size = 16
desired_capacity = 8
```

## Monitoring & Alerting

### CloudWatch Metrics

- Network bandwidth utilization
- EFA packet drops
- Instance health metrics
- Storage performance

### Alarms

Automatic alarms for:
- High packet loss
- Bandwidth saturation
- EFA errors
- High latency

### Logging

- System logs
- Performance benchmarks
- EFA diagnostics
- Custom application logs

## Troubleshooting

### Common Issues

#### EFA Not Working
```bash
# Check EFA installation
fi_info -l

# Verify network interface
ip link show | grep efa

# Check security groups
aws ec2 describe-security-groups --group-ids sg-xxxxx
```

#### Performance Issues
```bash
# Run performance benchmark
/usr/local/bin/hpc-benchmark.sh

# Check network statistics
ethtool -S mlx5_0

# Monitor system resources
htop
iotop
```

#### FSx Mount Issues
```bash
# Check FSx status
aws fsx describe-file-systems --file-system-ids fs-xxxxx

# Verify mount point
df -h /fsx

# Check Lustre client
lfs df
```

### Debug Commands

```bash
# System information
/usr/local/bin/system-info.sh

# Network diagnostics
iperf3 -c <target_ip>
netperf -H <target_ip>

# GPU diagnostics
nvidia-smi
nvidia-smi topo -m

# EFA diagnostics
fi_info -l
fi_pingpong -e rdm -I 1 -W 5
```

## Examples

### AWS Examples

#### Basic Training Cluster
See `examples/basic/` for a simple 8-node training cluster.

#### Advanced Auto Scaling
See `examples/advanced/` for auto-scaling configuration.

#### Multi-Region Setup
See `examples/multi-region/` for cross-region deployment.

#### Terragrunt Integration
See `examples/terragrunt/` for Terragrunt configuration with remote state management.

### Azure Examples

#### Basic HPC Cluster
See `examples/azure-basic/` for a simple 8-node HPC cluster with InfiniBand and Azure NetApp Files.

#### Advanced Auto-Scaling
See `examples/azure-advanced/` for production HPC cluster with auto-scaling and comprehensive monitoring.

#### Terragrunt Integration
See `examples/azure-terragrunt/` for Azure HPC deployment with remote state management.

For detailed information about Azure examples, see `examples/azure-README.md`.

## Testing

### Unit Tests
```bash
cd tests
go test -v ./...
```

### Integration Tests
```bash
# Deploy test infrastructure
terraform init
terraform plan
terraform apply

# Run performance tests
./scripts/run-perf-tests.sh

# Cleanup
terraform destroy
```

## License

This module is licensed under the MIT License. See LICENSE file for details.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## Support

For support and questions:
- Create an issue in the repository
- Check the troubleshooting section
- Review CloudWatch logs for diagnostics

## Version History

### v1.0.0
- Initial release
- EFA support
- FSx for Lustre integration
- Auto scaling capabilities
- Complete monitoring

---

**Note**: This module is designed for production use with high-performance computing workloads. Ensure proper testing in your environment before deployment.