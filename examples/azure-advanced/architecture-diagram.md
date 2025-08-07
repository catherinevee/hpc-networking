# Azure Advanced HPC Architecture Diagram

## Overview
This diagram shows the Terraform components and their relationships in the advanced Azure HPC example with auto-scaling, enhanced security, and comprehensive monitoring.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                  Azure Advanced HPC Infrastructure                              │
├─────────────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────────────────────────┐ │
│  │                              Resource Group: hpc-advanced-rg                              │ │
│  │                                    Location: East US                                       │ │
│  └─────────────────────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────────────────────────┐ │
│  │                              Virtual Network: hpc-advanced-vnet                           │ │
│  │                                Address Space: 10.0.0.0/16                                 │ │
│  └─────────────────────────────────────────────────────────────────────────────────────────────┘ │
│                                           │                                                    │
│                                           │                                                    │
│  ┌─────────────────────────────────────────────────────────────────────────────────────────────┐ │
│  │                                        Subnets                                             │ │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐                            │ │
│  │  │  Compute Subnet │  │  Storage Subnet │  │ Endpoints Subnet│                            │ │
│  │  │  10.0.10.0/22  │  │  10.0.20.0/24  │  │  10.0.30.0/24  │                            │ │
│  │  └─────────────────┘  └─────────────────┘  └─────────────────┘                            │ │
│  └─────────────────────────────────────────────────────────────────────────────────────────────┘ │
│           │                           │                           │                            │
│           │                           │                           │                            │
│  ┌─────────────────────────────────────────────────────────────────────────────────────────────┐ │
│  │                              Enhanced Network Security Groups                             │ │
│  │  ┌─────────────────────────────────────────────────────────────────────────────────────────┐ │ │
│  │  │  Compute NSG (Enhanced)                                                               │ │ │
│  │  │  • SSH (22) - Restricted to bastion                                                    │ │ │
│  │  │  • InfiniBand - Internal only                                                          │ │ │
│  │  │  • Custom HPC ports (1024-65535)                                                       │ │ │
│  │  │  • Deny all other inbound                                                              │ │ │
│  │  └─────────────────────────────────────────────────────────────────────────────────────────┘ │ │
│  │  ┌─────────────────────────────────────────────────────────────────────────────────────────┐ │ │
│  │  │  Storage NSG (Enhanced)                                                                │ │ │
│  │  │  • NFS (2049) - Compute subnet only                                                    │ │ │
│  │  │  │  • InfiniBand - Internal only                                                       │ │ │
│  │  │  • Deny all other inbound                                                              │ │ │
│  │  └─────────────────────────────────────────────────────────────────────────────────────────┘ │ │
│  │  ┌─────────────────────────────────────────────────────────────────────────────────────────┐ │ │
│  │  │  Endpoints NSG (Enhanced)                                                              │ │ │
│  │  │  • Private Endpoints - Azure services                                                  │ │ │
│  │  │  • HTTPS (443) - Internal only                                                         │ │ │
│  │  │  • Deny all other inbound                                                              │ │ │
│  │  └─────────────────────────────────────────────────────────────────────────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────────────────────────────────────────┘ │
│                                           │                                                    │
│                                           │                                                    │
│  ┌─────────────────────────────────────────────────────────────────────────────────────────────┐ │
│  │                              Security & Identity Management                               │ │
│  │  ┌─────────────────────────────────────────────────────────────────────────────────────────┐ │ │
│  │  │                    Key Vault: hpc-key-vault                                            │ │ │
│  │  │                    • Secrets management                                                │ │ │
│  │  │                    • Key encryption                                                    │ │ │
│  │  │                    • Certificate storage                                               │ │ │
│  │  │                    • Soft delete enabled                                               │ │ │
│  │  └─────────────────────────────────────────────────────────────────────────────────────────┘ │ │
│  │                                           │                                                 │ │
│  │  ┌─────────────────────────────────────────────────────────────────────────────────────────┐ │ │
│  │  │                    User-Assigned Managed Identity: hpc-advanced-identity              │ │ │
│  │  │                    • Key Vault access policies                                        │ │ │
│  │  │                    • Azure Monitor permissions                                        │ │ │
│  │  │                    • Storage account access                                           │ │ │
│  │  └─────────────────────────────────────────────────────────────────────────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────────────────────────────────────────┘ │
│                                           │                                                    │
│                                           │                                                    │
│  ┌─────────────────────────────────────────────────────────────────────────────────────────────┐ │
│  │                              Azure NetApp Files Storage (Enhanced)                        │ │
│  │  ┌─────────────────────────────────────────────────────────────────────────────────────────┐ │ │
│  │  │                    NetApp Account: hpc-advanced-netapp                                │ │ │
│  │  │                    • Premium tier                                                     │ │ │
│  │  │                    • Encryption at rest                                               │ │ │
│  │  └─────────────────────────────────────────────────────────────────────────────────────────┘ │ │
│  │                                           │                                                 │ │
│  │  ┌─────────────────────────────────────────────────────────────────────────────────────────┐ │ │
│  │  │                    Capacity Pool: hpc-advanced-pool                                  │ │ │
│  │  │                    • 56 TB capacity                                                   │ │ │
│  │  │                    • Premium service level                                            │ │ │
│  │  │                    • Auto QoS enabled                                                 │ │ │
│  │  └─────────────────────────────────────────────────────────────────────────────────────────┘ │ │
│  │                                           │                                                 │ │
│  │  ┌─────────────────────────────────────────────────────────────────────────────────────────┐ │ │
│  │  │                    Volume: hpc-advanced-volume                                       │ │ │
│  │  │                    • 56 TB size                                                       │ │ │
│  │  │                    • NFS v4.1 protocol                                                │ │ │
│  │  │                    • Export policy restrictions                                       │ │ │
│  │  │                    • Mount point: /mnt/hpc-storage                                    │ │ │
│  │  └─────────────────────────────────────────────────────────────────────────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────────────────────────────────────────┘ │
│                                           │                                                    │
│                                           │                                                    │
│  ┌─────────────────────────────────────────────────────────────────────────────────────────────┐ │
│  │                              Auto-Scaling VM Scale Set                                   │ │
│  │  ┌─────────────────────────────────────────────────────────────────────────────────────────┐ │ │
│  │  │                    Instance Configuration                                             │ │ │
│  │  │                    • SKU: Standard_HB120rs_v3                                        │ │ │
│  │  │                    • Initial: 8 instances                                            │ │ │
│  │  │                    • Min: 2 instances                                                │ │ │
│  │  │                    • Max: 16 instances                                               │ │ │
│  │  │                    • OS: CentOS-HPC 7.9                                              │ │ │
│  │  │                    • Storage: Premium_LRS                                            │ │ │
│  │  └─────────────────────────────────────────────────────────────────────────────────────────┘ │ │
│  │                                           │                                                 │ │
│  │  ┌─────────────────────────────────────────────────────────────────────────────────────────┐ │ │
│  │  │                    Auto Scaling Rules                                                │ │ │
│  │  │                    • Scale Up: CPU > 70% for 10 min                                  │ │ │
│  │  │                    • Scale Down: CPU < 30% for 10 min                                │ │ │
│  │  │                    • Cooldown: 5 minutes                                             │ │ │
│  │  │                    • Increment: 1 instance                                           │ │ │
│  │  └─────────────────────────────────────────────────────────────────────────────────────────┘ │ │
│  │                                           │                                                 │ │
│  │  ┌─────────────────────────────────────────────────────────────────────────────────────────┐ │ │
│  │  │                    Enhanced User Data Script                                         │ │ │
│  │  │                    • InfiniBand configuration                                        │ │ │
│  │  │                    • NetApp Files mounting                                           │ │ │
│  │  │                    • Advanced system tuning                                          │ │ │
│  │  │                    • Azure Monitor agent setup                                       │ │ │
│  │  │                    • Performance monitoring scripts                                  │ │ │
│  │  │                    • Security hardening                                              │ │ │
│  │  └─────────────────────────────────────────────────────────────────────────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────────────────────────────────────────┘ │
│                                           │                                                    │
│                                           │                                                    │
│  ┌─────────────────────────────────────────────────────────────────────────────────────────────┐ │
│  │                              Comprehensive Monitoring & Alerting                          │ │
│  │  ┌─────────────────────────────────────────────────────────────────────────────────────────┐ │ │
│  │  │                    Application Insights: hpc-advanced-insights                        │ │ │
│  │  │                    • Application performance monitoring                               │ │ │
│  │  │                    • Custom metrics collection                                       │ │ │
│  │  │                    • 90-day data retention                                           │ │ │
│  │  │                    • Smart detection alerts                                          │ │ │
│  │  └─────────────────────────────────────────────────────────────────────────────────────────┘ │ │
│  │                                           │                                                 │ │
│  │  ┌─────────────────────────────────────────────────────────────────────────────────────────┐ │ │
│  │  │                    Log Analytics Workspace: hpc-advanced-workspace                    │ │ │
│  │  │                    • Centralized logging                                             │ │ │
│  │  │                    • 90-day retention                                                │ │ │
│  │  │                    • Custom queries and dashboards                                   │ │ │
│  │  │                    • Performance counters collection                                 │ │ │
│  │  └─────────────────────────────────────────────────────────────────────────────────────────┘ │ │
│  │                                           │                                                 │ │
│  │  ┌─────────────────────────────────────────────────────────────────────────────────────────┐ │ │
│  │  │                    Action Groups & Alert Rules                                       │ │ │
│  │  │                    • CPU utilization alerts                                          │ │ │
│  │  │                    • Memory usage alerts                                             │ │ │
│  │  │                    • Network performance alerts                                      │ │ │
│  │  │                    • Storage capacity alerts                                         │ │ │
│  │  │                    • Email and webhook notifications                                 │ │ │
│  │  └─────────────────────────────────────────────────────────────────────────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────────────────────────────────────────┘ │
│                                           │                                                    │
│                                           │                                                    │
│  ┌─────────────────────────────────────────────────────────────────────────────────────────────┐ │
│  │                              Private Endpoints (Cost Optimization)                        │ │
│  │  ┌─────────────────────────────────────────────────────────────────────────────────────────┐ │ │
│  │  │                    Private Endpoints                                                 │ │ │
│  │  │                    • Key Vault Private Endpoint                                      │ │ │
│  │  │                    • Storage Account Private Endpoint                                │ │ │
│  │  │                    • Application Insights Private Endpoint                           │ │ │
│  │  │                    • Log Analytics Private Endpoint                                  │ │ │
│  │  │                    • Reduced egress costs                                            │ │ │
│  │  │                    • Enhanced security                                               │ │ │
│  │  └─────────────────────────────────────────────────────────────────────────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────────────────────┘

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
│       ├── azurerm_subnet_network_security_group_association.endpoints
│       └── azurerm_private_endpoint.* (multiple)
├── azurerm_proximity_placement_group.hpc
│   └── azurerm_linux_virtual_machine_scale_set.hpc
├── azurerm_user_assigned_identity.hpc
│   ├── azurerm_linux_virtual_machine_scale_set.hpc
│   ├── azurerm_key_vault_access_policy.hpc
│   └── azurerm_monitor_diagnostic_setting.hpc
├── azurerm_key_vault.hpc
│   ├── azurerm_key_vault_access_policy.hpc
│   └── azurerm_private_endpoint.key_vault
├── azurerm_netapp_account.hpc
│   └── azurerm_netapp_pool.hpc
│       └── azurerm_netapp_volume.hpc
│           └── azurerm_linux_virtual_machine_scale_set.hpc (user_data)
├── azurerm_linux_virtual_machine_scale_set.hpc
│   └── azurerm_monitor_autoscale_setting.hpc
├── azurerm_application_insights.hpc
│   └── azurerm_private_endpoint.app_insights
├── azurerm_log_analytics_workspace.hpc
│   ├── azurerm_private_endpoint.log_analytics
│   └── azurerm_monitor_diagnostic_setting.hpc
└── azurerm_action_group.hpc
    └── azurerm_monitor_metric_alert.* (multiple)
```

### Auto-Scaling Flow
1. **Monitoring**: Azure Monitor collects metrics from VMSS
2. **Evaluation**: Auto-scaling rules evaluate CPU utilization
3. **Decision**: Scale up/down based on thresholds
4. **Action**: Add/remove instances with cooldown period
5. **Integration**: New instances run enhanced user data script

### Security Flow
1. **Identity**: Managed identity provides secure access
2. **Secrets**: Key Vault stores sensitive configuration
3. **Network**: Private endpoints secure service communication
4. **Monitoring**: Enhanced logging and alerting
5. **Compliance**: Audit trails and access controls

### Data Flow
1. **Network Setup**: VNet → Subnets → Enhanced NSGs → Private Endpoints
2. **Security Setup**: Key Vault → Access Policies → Managed Identity
3. **Storage Setup**: NetApp Account → Pool → Volume with encryption
4. **Compute Setup**: VMSS with auto-scaling and enhanced security
5. **Monitoring Setup**: Application Insights + Log Analytics + Alert Rules
6. **Integration**: Enhanced user data script with monitoring agents

### Key Outputs
- `resource_group_name`: Resource group identifier
- `virtual_network_name`: VNet identifier
- `compute_subnet_id`: Compute subnet for VMSS
- `netapp_mount_command`: Command to mount NetApp Files
- `vmss_name`: VM Scale Set identifier
- `proximity_placement_group_id`: Placement group for low latency
- `key_vault_id`: Key Vault identifier
- `key_vault_uri`: Key Vault URI for secrets access
- `application_insights_key`: Monitoring instrumentation key
- `log_analytics_workspace_id`: Logging workspace identifier
- `autoscale_setting_id`: Auto-scaling configuration identifier
- `action_group_id`: Alert action group identifier 