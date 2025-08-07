# Azure Terragrunt HPC Architecture Diagram

## Overview
This diagram shows how Terragrunt manages the Terraform components and their relationships in the Azure HPC deployment with remote state management and centralized configuration.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                  Azure Terragrunt HPC Infrastructure                           │
├─────────────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────────────────────────┐ │
│  │                              Terragrunt Configuration Layer                                │ │
│  │  ┌─────────────────────────────────────────────────────────────────────────────────────────┐ │ │
│  │  │                    Root Configuration (root.hcl)                                       │ │ │
│  │  │                    • Remote state backend configuration                                │ │ │
│  │  │                    • Global provider settings                                          │ │ │
│  │  │                    • Default tags and features                                         │ │ │
│  │  │                    • Version constraints                                               │ │ │
│  │  └─────────────────────────────────────────────────────────────────────────────────────────┘ │ │
│  │                                           │                                                 │ │
│  │  ┌─────────────────────────────────────────────────────────────────────────────────────────┐ │ │
│  │  │                    Module Configuration (terragrunt.hcl)                              │ │ │
│  │  │                    • Input variables for HPC module                                   │ │ │
│  │  │                    • Environment-specific settings                                    │ │ │
│  │  │                    • Resource naming conventions                                      │ │ │
│  │  │                    • Auto-scaling parameters                                          │ │ │
│  │  └─────────────────────────────────────────────────────────────────────────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────────────────────────────────────────┘ │
│                                           │                                                    │
│                                           │                                                    │
│  ┌─────────────────────────────────────────────────────────────────────────────────────────────┐ │
│  │                              Remote State Management                                      │ │
│  │  ┌─────────────────────────────────────────────────────────────────────────────────────────┐ │ │
│  │  │                    Azure Storage Account: hpcterraformstate                           │ │ │
│  │  │                    • Container: terraform-state                                        │ │ │
│  │  │                    • Key: azure-terragrunt/terraform.tfstate                          │ │ │
│  │  │                    • State locking and consistency                                     │ │ │
│  │  │                    • Team collaboration support                                        │ │ │
│  │  └─────────────────────────────────────────────────────────────────────────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────────────────────────────────────────┘ │
│                                           │                                                    │
│                                           │                                                    │
│  ┌─────────────────────────────────────────────────────────────────────────────────────────────┐ │
│  │                              Generated Terraform Files                                    │ │
│  │  ┌─────────────────────────────────────────────────────────────────────────────────────────┐ │ │
│  │  │                    backend.tf (Generated)                                             │ │ │
│  │  │                    • Azure Storage backend configuration                              │ │ │
│  │  │                    • State file location and locking                                  │ │ │
│  │  └─────────────────────────────────────────────────────────────────────────────────────────┘ │ │
│  │                                           │                                                 │ │
│  │  ┌─────────────────────────────────────────────────────────────────────────────────────────┐ │ │
│  │  │                    providers.tf (Generated)                                           │ │ │
│  │  │                    • Azure provider configuration                                     │ │ │
│  │  │                    • Version constraints                                              │ │ │
│  │  │                    • Default tags and features                                        │ │ │
│  │  └─────────────────────────────────────────────────────────────────────────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────────────────────────────────────────┘ │
│                                           │                                                    │
│                                           │                                                    │
│  ┌─────────────────────────────────────────────────────────────────────────────────────────────┐ │
│  │                              Azure HPC Infrastructure (Deployed)                          │ │
│  │                                                                                             │ │
│  │  ┌─────────────────────────────────────────────────────────────────────────────────────────┐ │ │
│  │  │                              Resource Group: hpc-networking-terragrunt-rg              │ │ │
│  │  │                                    Location: East US                                   │ │ │
│  │  └─────────────────────────────────────────────────────────────────────────────────────────┘ │ │
│  │                                           │                                                 │ │
│  │  ┌─────────────────────────────────────────────────────────────────────────────────────────┐ │ │
│  │  │                              Virtual Network: hpc-terragrunt-vnet                     │ │ │
│  │  │                                Address Space: 10.0.0.0/16                             │ │ │
│  │  └─────────────────────────────────────────────────────────────────────────────────────────┘ │ │
│  │                                           │                                                 │ │
│  │  ┌─────────────────────────────────────────────────────────────────────────────────────────┐ │ │
│  │  │                                        Subnets                                         │ │ │
│  │  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐                        │ │ │
│  │  │  │  Compute Subnet │  │  Storage Subnet │  │ Endpoints Subnet│                        │ │ │
│  │  │  │  10.0.10.0/22  │  │  10.0.20.0/24  │  │  10.0.30.0/24  │                        │ │ │
│  │  │  └─────────────────┘  └─────────────────┘  └─────────────────┘                        │ │ │
│  │  └─────────────────────────────────────────────────────────────────────────────────────────┘ │ │
│  │           │                           │                           │                        │ │
│  │           │                           │                           │                        │ │
│  │  ┌─────────────────────────────────────────────────────────────────────────────────────────┐ │ │
│  │  │                              Core Infrastructure Components                           │ │ │
│  │  │  ┌─────────────────────────────────────────────────────────────────────────────────────┐ │ │ │
│  │  │  │                    Proximity Placement Group: hpc-terragrunt-ppg                  │ │ │ │
│  │  │  │                    • Low-latency networking                                       │ │ │ │
│  │  │  │                    • Optimized for HPC workloads                                  │ │ │ │
│  │  │  └─────────────────────────────────────────────────────────────────────────────────────┘ │ │ │
│  │  │                                           │                                             │ │ │
│  │  │  ┌─────────────────────────────────────────────────────────────────────────────────────┐ │ │ │
│  │  │  │                    User-Assigned Managed Identity: hpc-terragrunt-identity        │ │ │ │
│  │  │  │                    • Access to Azure services                                     │ │ │ │
│  │  │  │                    • No secrets management required                                │ │ │ │
│  │  │  └─────────────────────────────────────────────────────────────────────────────────────┘ │ │ │
│  │  └─────────────────────────────────────────────────────────────────────────────────────────┘ │ │
│  │                                           │                                                 │ │
│  │  ┌─────────────────────────────────────────────────────────────────────────────────────────┐ │ │
│  │  │                              Azure NetApp Files Storage                               │ │ │
│  │  │  ┌─────────────────────────────────────────────────────────────────────────────────────┐ │ │ │
│  │  │  │                    NetApp Account: hpc-terragrunt-netapp                          │ │ │ │
│  │  │  │                    • Premium tier                                                 │ │ │ │
│  │  │  └─────────────────────────────────────────────────────────────────────────────────────┘ │ │ │
│  │  │                                           │                                             │ │ │
│  │  │  ┌─────────────────────────────────────────────────────────────────────────────────────┐ │ │ │
│  │  │  │                    Capacity Pool: hpc-terragrunt-pool                             │ │ │ │
│  │  │  │                    • 28 TB capacity                                               │ │ │ │
│  │  │  │                    • Premium service level                                        │ │ │ │
│  │  │  └─────────────────────────────────────────────────────────────────────────────────────┘ │ │ │
│  │  │                                           │                                             │ │ │
│  │  │  ┌─────────────────────────────────────────────────────────────────────────────────────┐ │ │ │
│  │  │  │                    Volume: hpc-terragrunt-volume                                   │ │ │ │
│  │  │  │                    • 28.8 TB size                                                 │ │ │ │
│  │  │  │                    • NFS v4.1 protocol                                            │ │ │ │
│  │  │  │                    • Mount point: /mnt/hpc-storage                                │ │ │ │
│  │  │  └─────────────────────────────────────────────────────────────────────────────────────┘ │ │ │
│  │  └─────────────────────────────────────────────────────────────────────────────────────────┘ │ │
│  │                                           │                                                 │ │
│  │  ┌─────────────────────────────────────────────────────────────────────────────────────────┐ │ │
│  │  │                              VM Scale Set: hpc-terragrunt-vmss                       │ │ │
│  │  │  ┌─────────────────────────────────────────────────────────────────────────────────────┐ │ │ │
│  │  │  │                    Instance Configuration                                         │ │ │ │
│  │  │  │                    • SKU: Standard_HB120rs_v3                                    │ │ │ │
│  │  │  │                    • Initial: 8 instances                                        │ │ │ │
│  │  │  │                    • Min: 2 instances (if auto-scaling)                          │ │ │ │
│  │  │  │                    • Max: 16 instances (if auto-scaling)                         │ │ │ │
│  │  │  │                    • OS: CentOS-HPC 7.9                                          │ │ │ │
│  │  │  └─────────────────────────────────────────────────────────────────────────────────────┘ │ │ │
│  │  │                                           │                                             │ │ │
│  │  │  ┌─────────────────────────────────────────────────────────────────────────────────────┐ │ │ │
│  │  │  │                    Auto Scaling (Conditional)                                     │ │ │ │
│  │  │  │                    • Scale Up: CPU > 70% for 10 min                              │ │ │ │
│  │  │  │                    • Scale Down: CPU < 30% for 10 min                            │ │ │ │
│  │  │  │                    • Cooldown: 5 minutes                                         │ │ │ │
│  │  │  └─────────────────────────────────────────────────────────────────────────────────────┘ │ │ │
│  │  └─────────────────────────────────────────────────────────────────────────────────────────┘ │ │
│  │                                           │                                                 │ │
│  │  ┌─────────────────────────────────────────────────────────────────────────────────────────┐ │ │
│  │  │                              Monitoring & Observability                              │ │ │
│  │  │  ┌─────────────────────────────────────────────────────────────────────────────────────┐ │ │ │
│  │  │  │                    Application Insights: hpc-terragrunt-insights                  │ │ │ │
│  │  │  │                    • Application monitoring                                       │ │ │ │
│  │  │  │                    • Performance metrics                                          │ │ │ │
│  │  │  └─────────────────────────────────────────────────────────────────────────────────────┘ │ │ │
│  │  │                                           │                                             │ │ │
│  │  │  ┌─────────────────────────────────────────────────────────────────────────────────────┐ │ │ │
│  │  │  │                    Log Analytics Workspace: hpc-terragrunt-workspace              │ │ │ │
│  │  │  │                    • Centralized logging                                          │ │ │ │
│  │  │  │                    • 90-day retention                                             │ │ │ │
│  │  │  └─────────────────────────────────────────────────────────────────────────────────────┘ │ │ │
│  │  └─────────────────────────────────────────────────────────────────────────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────────────────────┘

## Terragrunt Configuration Flow

### 1. Root Configuration (root.hcl)
```
Remote State Configuration
├── Backend: azurerm
├── Resource Group: hpc-terragrunt-state-rg
├── Storage Account: hpcterraformstate
├── Container: terraform-state
└── Key: ${path_relative_to_include()}/terraform.tfstate

Provider Configuration
├── Required Version: 1.12.2
├── Azure Provider: 3.95.0
├── Random Provider: 3.6.0
├── Key Vault Features
└── Default Tags
```

### 2. Module Configuration (terragrunt.hcl)
```
Input Variables
├── Resource Group Configuration
│   ├── resource_group_name: "hpc-networking-terragrunt-rg"
│   └── location: "East US"
├── Virtual Network Configuration
│   ├── virtual_network_name: "hpc-terragrunt-vnet"
│   └── address_space: ["10.0.0.0/16"]
├── Subnet Configuration
│   ├── compute_subnet_cidr: "10.0.10.0/22"
│   ├── storage_subnet_cidr: "10.0.20.0/24"
│   └── endpoints_subnet_cidr: "10.0.30.0/24"
├── VM Scale Set Configuration
│   ├── vmss_name: "hpc-terragrunt-vmss"
│   ├── vm_sku: "Standard_HB120rs_v3"
│   └── instances: 8
├── Auto Scaling Configuration
│   ├── enable_autoscaling: true
│   ├── min_size: 2
│   ├── max_size: 16
│   └── desired_capacity: 8
├── Storage Configuration
│   ├── enable_netapp_files: true
│   ├── netapp_storage_tb: 28
│   └── netapp_volume_gb: 28800
├── Security Configuration
│   ├── enable_key_vault: true
│   ├── enable_encryption: true
│   └── allowed_cidr_blocks: ["10.0.0.0/16", "192.168.1.0/24"]
├── Monitoring Configuration
│   ├── enable_application_insights: true
│   ├── enable_log_analytics: true
│   └── log_retention_days: 90
└── Tags
    ├── Environment: "prod"
    ├── Project: "terragrunt-training"
    ├── Owner: "AI-Research"
    ├── CostCenter: "AI-Infrastructure"
    ├── DataClass: "Confidential"
    ├── Purpose: "Terragrunt Training Cluster"
    ├── AutoScaling: "enabled"
    └── ManagedBy: "terragrunt"
```

## Terraform Component Relationships

### Resource Dependencies
```
azurerm_resource_group.hpc
├── azurerm_virtual_network.hpc
│   ├── azurerm_subnet.compute
│   │   ├── azurerm_network_security_group.compute
│   │   ├── azurerm_subnet_network_security_group_association.compute
│   │   └── azurerm_linux_virtual_machine_scale_set.hpc (NIC)
│   ├── azurerm_subnet.storage
│   │   ├── azurerm_network_security_group.storage
│   │   └── azurerm_subnet_network_security_group_association.storage
│   └── azurerm_subnet.endpoints
│       ├── azurerm_network_security_group.endpoints
│       └── azurerm_subnet_network_security_group_association.endpoints
├── azurerm_proximity_placement_group.hpc
│   └── azurerm_linux_virtual_machine_scale_set.hpc
├── azurerm_user_assigned_identity.hpc
│   └── azurerm_linux_virtual_machine_scale_set.hpc
├── azurerm_netapp_account.hpc
│   └── azurerm_netapp_pool.hpc
│       └── azurerm_netapp_volume.hpc
│           └── azurerm_linux_virtual_machine_scale_set.hpc (user_data)
├── azurerm_application_insights.hpc
└── azurerm_log_analytics_workspace.hpc
```

### Terragrunt Workflow
1. **Initialization**: `terragrunt init`
   - Downloads providers
   - Configures remote state backend
   - Sets up Azure Storage connection

2. **Planning**: `terragrunt plan`
   - Reads input variables from terragrunt.hcl
   - Generates Terraform configuration
   - Shows planned changes

3. **Application**: `terragrunt apply`
   - Deploys infrastructure
   - Stores state in Azure Storage
   - Manages state locking

4. **State Management**: `terragrunt state`
   - Remote state operations
   - Team collaboration
   - State consistency

### Key Benefits
- **DRY Principle**: Centralized configuration in root.hcl
- **Remote State**: Team collaboration and state consistency
- **Environment Management**: Easy environment-specific configurations
- **Dependency Management**: Automatic dependency resolution
- **Version Control**: Consistent provider and Terraform versions
- **Security**: Centralized secrets and access management

### Generated Files
- `backend.tf`: Remote state configuration
- `providers.tf`: Provider configuration with versions
- `versions.tf`: Terraform version constraints
- `.terragrunt-cache/`: Local cache directory

### State File Structure
```
Azure Storage Account: hpcterraformstate
└── Container: terraform-state
    └── Key: azure-terragrunt/terraform.tfstate
        ├── Resources
        ├── Outputs
        ├── Backend Configuration
        └── State Metadata
``` 