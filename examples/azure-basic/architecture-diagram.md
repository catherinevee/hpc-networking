# Azure Basic HPC Architecture Diagram

## Overview
This diagram shows the Terraform components and their relationships in the basic Azure HPC example.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                    Azure Basic HPC Infrastructure                                │
├─────────────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────────────────────────┐ │
│  │                              Resource Group: hpc-networking-rg                             │ │
│  │                                    Location: East US                                       │ │
│  └─────────────────────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────────────────────────┐ │
│  │                              Virtual Network: hpc-vnet                                     │ │
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
│  │                              Network Security Groups                                      │ │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐                            │ │
│  │  │  Compute NSG    │  │  Storage NSG    │  │ Endpoints NSG   │                            │ │
│  │  │ • SSH (22)      │  │ • NFS (2049)    │  │ • Private       │                            │ │
│  │  │ • InfiniBand    │  │ • InfiniBand    │  │   Endpoints     │                            │ │
│  │  │ • All internal  │  │ • All internal  │  │ • HTTPS (443)   │                            │ │
│  │  └─────────────────┘  └─────────────────┘  └─────────────────┘                            │ │
│  └─────────────────────────────────────────────────────────────────────────────────────────────┘ │
│           │                           │                           │                            │
│           │                           │                           │                            │
│  ┌─────────────────────────────────────────────────────────────────────────────────────────────┐ │
│  │                              Core Infrastructure Components                               │ │
│  │                                                                                             │ │
│  │  ┌─────────────────────────────────────────────────────────────────────────────────────────┐ │ │
│  │  │                    Proximity Placement Group: hpc-ppg                                  │ │ │
│  │  │                    • Low-latency networking                                           │ │ │
│  │  │                    • Optimized for HPC workloads                                      │ │ │
│  │  └─────────────────────────────────────────────────────────────────────────────────────────┘ │ │
│  │                                           │                                                 │ │
│  │  ┌─────────────────────────────────────────────────────────────────────────────────────────┐ │ │
│  │  │                    User-Assigned Managed Identity: hpc-identity                        │ │ │
│  │  │                    • Access to Azure services                                         │ │ │
│  │  │                    • No secrets management required                                    │ │ │
│  │  └─────────────────────────────────────────────────────────────────────────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────────────────────────────────────────┘ │
│                                           │                                                    │
│                                           │                                                    │
│  ┌─────────────────────────────────────────────────────────────────────────────────────────────┐ │
│  │                              Azure NetApp Files Storage                                   │ │
│  │  ┌─────────────────────────────────────────────────────────────────────────────────────────┐ │ │
│  │  │                    NetApp Account: hpc-netapp-account                                 │ │ │
│  │  │                    • Premium tier                                                     │ │ │
│  │  └─────────────────────────────────────────────────────────────────────────────────────────┘ │ │
│  │                                           │                                                 │ │
│  │  ┌─────────────────────────────────────────────────────────────────────────────────────────┐ │ │
│  │  │                    Capacity Pool: hpc-pool                                            │ │ │
│  │  │                    • 28 TB capacity                                                   │ │ │
│  │  │                    • Premium service level                                            │ │ │
│  │  └─────────────────────────────────────────────────────────────────────────────────────────┘ │ │
│  │                                           │                                                 │ │
│  │  ┌─────────────────────────────────────────────────────────────────────────────────────────┐ │ │
│  │  │                    Volume: hpc-volume                                                 │ │ │
│  │  │                    • 28.8 TB size                                                     │ │ │
│  │  │                    • NFS v4.1 protocol                                                │ │ │
│  │  │                    • Mount point: /mnt/hpc-storage                                    │ │ │
│  │  └─────────────────────────────────────────────────────────────────────────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────────────────────────────────────────┘ │
│                                           │                                                    │
│                                           │                                                    │
│  ┌─────────────────────────────────────────────────────────────────────────────────────────────┐ │
│  │                              VM Scale Set: hpc-vmss                                      │ │
│  │  ┌─────────────────────────────────────────────────────────────────────────────────────────┐ │ │
│  │  │                    Instance Configuration                                             │ │ │
│  │  │                    • SKU: Standard_HB120rs_v3                                        │ │ │
│  │  │                    • Count: 8 instances                                              │ │ │
│  │  │                    • OS: CentOS-HPC 7.9                                              │ │ │
│  │  │                    • Storage: Premium_LRS                                            │ │ │
│  │  └─────────────────────────────────────────────────────────────────────────────────────────┘ │ │
│  │                                           │                                                 │ │
│  │  ┌─────────────────────────────────────────────────────────────────────────────────────────┐ │ │
│  │  │                    Network Configuration                                              │ │ │
│  │  │                    • Primary NIC in compute subnet                                   │ │ │
│  │  │                    • InfiniBand support                                              │ │ │
│  │  │                    • Proximity placement group                                       │ │ │
│  │  └─────────────────────────────────────────────────────────────────────────────────────────┘ │ │
│  │                                           │                                                 │ │
│  │  ┌─────────────────────────────────────────────────────────────────────────────────────────┐ │ │
│  │  │                    User Data Script                                                  │ │ │
│  │  │                    • InfiniBand configuration                                        │ │ │
│  │  │                    • NetApp Files mounting                                           │ │ │
│  │  │                    • System tuning                                                   │ │ │
│  │  │                    • HPC user setup                                                  │ │ │
│  │  └─────────────────────────────────────────────────────────────────────────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────────────────────────────────────────┘ │
│                                           │                                                    │
│                                           │                                                    │
│  ┌─────────────────────────────────────────────────────────────────────────────────────────────┐ │
│  │                              Monitoring & Observability                                  │ │
│  │  ┌─────────────────────────────────────────────────────────────────────────────────────────┐ │ │
│  │  │                    Application Insights: hpc-insights                                │ │ │
│  │  │                    • Application monitoring                                          │ │ │
│  │  │                    • Performance metrics                                             │ │ │
│  │  │                    • Instrumentation key output                                      │ │ │
│  │  └─────────────────────────────────────────────────────────────────────────────────────────┘ │ │
│  │                                           │                                                 │ │
│  │  ┌─────────────────────────────────────────────────────────────────────────────────────────┐ │ │
│  │  │                    Log Analytics Workspace: hpc-workspace                             │ │ │
│  │  │                    • Centralized logging                                             │ │ │
│  │  │                    • 30-day retention                                                │ │ │
│  │  │                    • Workspace ID output                                             │ │ │
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

### Data Flow
1. **Network Setup**: VNet → Subnets → NSGs → Associations
2. **Storage Setup**: NetApp Account → Pool → Volume
3. **Compute Setup**: VMSS with proximity placement and managed identity
4. **Monitoring Setup**: Application Insights and Log Analytics
5. **Integration**: User data script mounts NetApp Files and configures InfiniBand

### Key Outputs
- `resource_group_name`: Resource group identifier
- `virtual_network_name`: VNet identifier
- `compute_subnet_id`: Compute subnet for VMSS
- `netapp_mount_command`: Command to mount NetApp Files
- `vmss_name`: VM Scale Set identifier
- `proximity_placement_group_id`: Placement group for low latency
- `application_insights_key`: Monitoring instrumentation key
- `log_analytics_workspace_id`: Logging workspace identifier 