# Azure HPC Examples Overview Diagram

## Overview
This diagram provides a comprehensive view of all three Azure HPC examples and their relationships, showing the progression from basic to advanced configurations.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                    Azure HPC Examples Overview                                  │
├─────────────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────────────────────────┐ │
│  │                              Example Progression & Complexity                              │ │
│  │                                                                                             │ │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐                            │ │
│  │  │   Basic Example │  │ Advanced Example│  │ Terragrunt      │                            │ │
│  │  │   (Simple)      │  │ (Production)    │  │ (Enterprise)    │                            │ │
│  │  └─────────────────┘  └─────────────────┘  └─────────────────┘                            │ │
│  │           │                       │                       │                                │ │
│  │           │                       │                       │                                │ │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐                            │ │
│  │  │ • 8-node cluster│  │ • Auto-scaling  │  │ • Remote state  │                            │ │
│  │  │ • Basic monitoring│ │ • Enhanced security│ │ • Team collaboration│                        │ │
│  │  │ • Simple setup  │  │ • Key Vault     │  │ • DRY config    │                            │ │
│  │  │ • Development   │  │ • Private endpoints│ │ • Environment mgmt│                          │ │
│  │  └─────────────────┘  └─────────────────┘  └─────────────────┘                            │ │
│  └─────────────────────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────────────────────────┐ │
│  │                              Common Infrastructure Components                              │ │
│  │                                                                                             │ │
│  │  ┌─────────────────────────────────────────────────────────────────────────────────────────┐ │ │
│  │  │                              Core Azure Services                                       │ │ │
│  │  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐                        │ │ │
│  │  │  │ Resource Group  │  │ Virtual Network │  │ Proximity       │                        │ │ │
│  │  │  │ • Container     │  │ • 10.0.0.0/16   │  │ Placement Group │                        │ │ │
│  │  │  │ • Location      │  │ • Subnets       │  │ • Low latency   │                        │ │ │
│  │  │  │ • Tags          │  │ • NSGs          │  │ • HPC optimized │                        │ │ │
│  │  │  └─────────────────┘  └─────────────────┘  └─────────────────┘                        │ │ │
│  │  └─────────────────────────────────────────────────────────────────────────────────────────┘ │ │
│  │                                           │                                                 │ │
│  │  ┌─────────────────────────────────────────────────────────────────────────────────────────┐ │ │
│  │  │                              Compute & Storage                                         │ │ │
│  │  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐                        │ │ │
│  │  │  │ VM Scale Set    │  │ Azure NetApp    │  │ Managed Identity│                        │ │ │
│  │  │  │ • H-Series VMs  │  │ Files           │  │ • Service access│                        │ │ │
│  │  │  │ • InfiniBand    │  │ • NFS v4.1      │  │ • No secrets    │                        │ │ │
│  │  │  │ • Auto-scaling  │  │ • High perf     │  │ • Secure auth   │                        │ │ │
│  │  │  └─────────────────┘  └─────────────────┘  └─────────────────┘                        │ │ │
│  │  └─────────────────────────────────────────────────────────────────────────────────────────┘ │ │
│  │                                           │                                                 │ │
│  │  ┌─────────────────────────────────────────────────────────────────────────────────────────┐ │ │
│  │  │                              Monitoring & Observability                                │ │ │
│  │  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐                        │ │ │
│  │  │  │ Application     │  │ Log Analytics   │  │ Alert Rules     │                        │ │ │
│  │  │  │ Insights        │  │ Workspace       │  │ • CPU/Memory    │                        │ │ │
│  │  │  │ • App monitoring│  │ • Centralized   │  │ • Network perf  │                        │ │ │
│  │  │  │ • Performance   │  │ • 90-day retention│ │ • Storage alerts│                        │ │ │
│  │  │  └─────────────────┘  └─────────────────┘  └─────────────────┘                        │ │ │
│  │  └─────────────────────────────────────────────────────────────────────────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────────────────────────┐ │
│  │                              Example-Specific Features                                    │ │
│  │                                                                                             │ │
│  │  ┌─────────────────────────────────────────────────────────────────────────────────────────┐ │ │
│  │  │                              Basic Example Features                                    │ │ │
│  │  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐                        │ │ │
│  │  │  │ Simple NSGs     │  │ Basic monitoring│  │ Fixed 8 nodes   │                        │ │ │
│  │  │  │ • SSH (22)      │  │ • App Insights  │  │ • No scaling    │                        │ │ │
│  │  │  │ • InfiniBand    │  │ • Log Analytics │  │ • Development   │                        │ │ │
│  │  │  │ • NFS (2049)    │  │ • 30-day retention│ │ • Testing       │                        │ │ │
│  │  │  └─────────────────┘  └─────────────────┘  └─────────────────┘                        │ │ │
│  │  └─────────────────────────────────────────────────────────────────────────────────────────┘ │ │
│  │                                           │                                                 │ │
│  │  ┌─────────────────────────────────────────────────────────────────────────────────────────┐ │ │
│  │  │                              Advanced Example Features                                 │ │ │
│  │  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐                        │ │ │
│  │  │  │ Enhanced NSGs   │  │ Key Vault       │  │ Auto-scaling    │                        │ │ │
│  │  │  │ • Restricted    │  │ • Secrets mgmt  │  │ • 2-16 nodes    │                        │ │ │
│  │  │  │ • Private endpoints│ │ • Encryption    │  │ • CPU-based     │                        │ │ │
│  │  │  │ • Enhanced security│ │ • Access policies│ │ • Cooldown       │                        │ │ │
│  │  │  └─────────────────┘  └─────────────────┘  └─────────────────┘                        │ │ │
│  │  └─────────────────────────────────────────────────────────────────────────────────────────┘ │ │
│  │                                           │                                                 │ │
│  │  ┌─────────────────────────────────────────────────────────────────────────────────────────┐ │ │
│  │  │                              Terragrunt Example Features                               │ │ │
│  │  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐                        │ │ │
│  │  │  │ Remote State    │  │ DRY Config      │  │ Team Collaboration│                       │ │ │
│  │  │  │ • Azure Storage │  │ • root.hcl      │  │ • State locking │                        │ │ │
│  │  │  │ • State locking │  │ • terragrunt.hcl│  │ • Version control│                        │ │ │
│  │  │  │ • Consistency   │  │ • Environment mgmt│ │ • Centralized   │                        │ │ │
│  │  │  └─────────────────┘  └─────────────────┘  └─────────────────┘                        │ │ │
│  │  └─────────────────────────────────────────────────────────────────────────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────────────────────────┐ │
│  │                              Deployment Workflows                                          │ │
│  │                                                                                             │ │
│  │  ┌─────────────────────────────────────────────────────────────────────────────────────────┐ │ │
│  │  │                              Basic Deployment                                           │ │ │
│  │  │  1. terraform init                                                                      │ │ │
│  │  │  2. terraform plan                                                                      │ │ │
│  │  │  3. terraform apply                                                                     │ │ │
│  │  │  4. Access HPC cluster                                                                  │ │ │
│  │  └─────────────────────────────────────────────────────────────────────────────────────────┘ │ │
│  │                                           │                                                 │ │
│  │  ┌─────────────────────────────────────────────────────────────────────────────────────────┐ │ │
│  │  │                              Advanced Deployment                                        │ │ │
│  │  │  1. terraform init                                                                      │ │ │
│  │  │  2. Configure Key Vault                                                                 │ │ │
│  │  │  3. terraform plan                                                                      │ │ │
│  │  │  4. terraform apply                                                                     │ │ │
│  │  │  5. Monitor auto-scaling                                                                │ │ │
│  │  └─────────────────────────────────────────────────────────────────────────────────────────┘ │ │
│  │                                           │                                                 │ │
│  │  ┌─────────────────────────────────────────────────────────────────────────────────────────┐ │ │
│  │  │                              Terragrunt Deployment                                      │ │ │
│  │  │  1. Setup Azure Storage                                                                 │ │ │
│  │  │  2. terragrunt init                                                                     │ │ │
│  │  │  3. terragrunt plan                                                                     │ │ │
│  │  │  4. terragrunt apply                                                                    │ │ │
│  │  │  5. Team collaboration                                                                  │ │ │
│  │  └─────────────────────────────────────────────────────────────────────────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────────────────────┘

## Component Comparison Matrix

### Infrastructure Components

| Component | Basic | Advanced | Terragrunt |
|-----------|-------|----------|------------|
| **Resource Group** | ✅ | ✅ | ✅ |
| **Virtual Network** | ✅ | ✅ | ✅ |
| **Subnets** | 3 (Compute, Storage, Endpoints) | 3 (Compute, Storage, Endpoints) | 3 (Compute, Storage, Endpoints) |
| **Network Security Groups** | Basic rules | Enhanced rules | Enhanced rules |
| **Proximity Placement Group** | ✅ | ✅ | ✅ |
| **Managed Identity** | ✅ | ✅ | ✅ |
| **VM Scale Set** | Fixed 8 nodes | Auto-scaling 2-16 nodes | Auto-scaling 2-16 nodes |
| **Azure NetApp Files** | 28.8 TB | 56 TB | 28.8 TB |
| **Application Insights** | ✅ | ✅ | ✅ |
| **Log Analytics** | ✅ | ✅ | ✅ |

### Advanced Features

| Feature | Basic | Advanced | Terragrunt |
|---------|-------|----------|------------|
| **Auto-scaling** | ❌ | ✅ | ✅ |
| **Key Vault** | ❌ | ✅ | ✅ |
| **Private Endpoints** | ❌ | ✅ | ✅ |
| **Enhanced Security** | ❌ | ✅ | ✅ |
| **Remote State** | ❌ | ❌ | ✅ |
| **Team Collaboration** | ❌ | ❌ | ✅ |
| **Environment Management** | ❌ | ❌ | ✅ |
| **DRY Configuration** | ❌ | ❌ | ✅ |

### Monitoring & Observability

| Component | Basic | Advanced | Terragrunt |
|-----------|-------|----------|------------|
| **Application Insights** | Basic monitoring | Enhanced monitoring | Enhanced monitoring |
| **Log Analytics** | 30-day retention | 90-day retention | 90-day retention |
| **Alert Rules** | ❌ | ✅ | ✅ |
| **Action Groups** | ❌ | ✅ | ✅ |
| **Custom Metrics** | ❌ | ✅ | ✅ |
| **Performance Counters** | ❌ | ✅ | ✅ |

### Security Features

| Feature | Basic | Advanced | Terragrunt |
|---------|-------|----------|------------|
| **Network Security** | Basic NSGs | Enhanced NSGs | Enhanced NSGs |
| **Secrets Management** | ❌ | Key Vault | Key Vault |
| **Encryption** | Default | Enhanced | Enhanced |
| **Private Endpoints** | ❌ | ✅ | ✅ |
| **Access Policies** | ❌ | ✅ | ✅ |
| **Audit Logging** | ❌ | ✅ | ✅ |

## Use Case Recommendations

### Basic Example
**Best For:**
- Development and testing environments
- Learning Azure HPC services
- Proof of concept deployments
- Small-scale training workloads
- Individual developers

**When to Use:**
- Quick setup needed
- Limited budget
- Simple requirements
- Learning purposes

### Advanced Example
**Best For:**
- Production workloads
- Large-scale training jobs
- Environments requiring auto-scaling
- Organizations with security requirements
- Performance-critical applications

**When to Use:**
- Production deployment
- Security compliance needed
- Auto-scaling required
- Enhanced monitoring needed

### Terragrunt Example
**Best For:**
- Multi-environment deployments
- Teams using Terragrunt
- Production environments requiring state management
- Organizations with multiple Azure subscriptions
- Enterprise deployments

**When to Use:**
- Team collaboration
- Multiple environments
- State management required
- DRY configuration needed
- Enterprise governance

## Migration Path

```
Basic Example
     │
     ▼
Advanced Example (Add auto-scaling, security, monitoring)
     │
     ▼
Terragrunt Example (Add remote state, team collaboration)
```

## Cost Comparison

| Component | Basic | Advanced | Terragrunt |
|-----------|-------|----------|------------|
| **Compute** | 8 × HB120rs_v3 | 2-16 × HB120rs_v3 | 2-16 × HB120rs_v3 |
| **Storage** | 28.8 TB NetApp | 56 TB NetApp | 28.8 TB NetApp |
| **Monitoring** | Basic | Enhanced | Enhanced |
| **Security** | Basic | Enhanced | Enhanced |
| **State Management** | Local | Local | Azure Storage |
| **Estimated Monthly** | $15K-20K | $10K-40K | $10K-40K + Storage |

## Performance Characteristics

| Metric | Basic | Advanced | Terragrunt |
|--------|-------|----------|------------|
| **Network Latency** | <50 μs | <50 μs | <50 μs |
| **Storage Throughput** | 28.8 GB/s | 56 GB/s | 28.8 GB/s |
| **Compute Capacity** | Fixed | Dynamic | Dynamic |
| **Scalability** | Manual | Automatic | Automatic |
| **Availability** | Standard | High | High | 