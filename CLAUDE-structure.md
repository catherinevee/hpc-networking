# AWS HPC Networking Infrastructure Deployment Prompt

## Complete Deployment Prompt

```
Create a production-ready Terragrunt deployment for a high-performance computing (HPC) networking infrastructure on AWS with the following specifications:

PROJECT CONTEXT:
- Application Type: Scientific computing cluster for computational fluid dynamics (CFD), molecular dynamics, weather modeling, and genomics research
- Expected Load: 10,000 core cluster capacity, 100+ concurrent jobs, 500TB scratch storage, 10PB long-term storage
- Environments: dev (small-scale testing), staging (performance validation), production (full-scale research)
- Regions: us-east-2 (Primary), eu-west-1 (Overflow capacity), ap-northeast-1 (Collaboration)
- User Base: 500 researchers, 50 research groups, 10 university partners
- Job Types: MPI jobs (80%), embarrassingly parallel (15%), GPU-accelerated (5%)

TECHNICAL REQUIREMENTS:

Compute Infrastructure:
- EC2 Instances:
  * HPC Optimized: hpc6a.48xlarge for CFD (96 vCPUs, 384 GiB RAM, 100 Gbps EFA)
  * Memory Optimized: x2iezn.32xlarge for genomics (128 vCPUs, 4 TiB RAM)
  * GPU Instances: p4d.24xlarge for ML/AI workloads (8x A100 GPUs)
  * General Purpose: m6i.32xlarge for pre/post-processing
  * Spot Instances: 70% spot, 30% on-demand for cost optimization
- Cluster Configuration:
  * AWS ParallelCluster 3.7+ with Slurm 23.x scheduler
  * Multiple queues: compute, memory, gpu, debug
  * Auto-scaling: Scale from 0 to 1000 nodes based on queue depth
  * Cluster placement groups for network optimization
  * Dedicated hosts for license-bound software

Advanced Networking:
- Elastic Fabric Adapter (EFA):
  * Enabled on all compute nodes for MPI communication
  * Kernel bypass for ultra-low latency (<15 microseconds)
  * GPUDirect RDMA support for GPU clusters
  * libfabric 1.18+ with AWS OFI NCCL plugin
- Cluster Networking:
  * Single Availability Zone deployment for minimal latency
  * Cluster placement groups with partition strategy
  * Enhanced networking with SR-IOV
  * Jumbo frames (9000 MTU) throughout
  * No oversubscription in network topology
- VPC Architecture:
  * Dedicated VPC with 10.0.0.0/16 CIDR
  * Private subnets only for compute nodes
  * Public subnet for head node and NAT gateways
  * VPC Endpoints for S3, DynamoDB, EC2, CloudWatch
  * AWS Transit Gateway for multi-region connectivity
- Network Performance:
  * 100 Gbps network performance for EFA-enabled instances
  * 200 Gbps aggregate bandwidth for storage access
  * Sub-millisecond latency for node-to-node communication
  * Network flow monitoring with VPC Flow Logs

Storage Architecture:
- High-Performance Storage:
  * FSx for Lustre: 1.2 GB/s per TiB throughput
    - Scratch: 500TB (SSD-based, 200 MB/s/TiB)
    - Persistent: 100TB (SSD-based, 1000 MB/s/TiB)
    - Data compression: LZ4 enabled
    - S3 data repository integration
  * EBS Optimized instances with io2 Block Express
    - 256,000 IOPS per volume
    - 4,000 MB/s throughput per volume
    - Multi-attach for shared storage
- Parallel File System:
  * BeeGFS on i3en.24xlarge instances (alternative to FSx)
  * 8 metadata servers, 16 storage servers
  * InfiniBand over Ethernet with RoCE v2
  * 10GB/s aggregate throughput
- Object Storage:
  * S3 for long-term data (Standard tier)
  * S3 Intelligent-Tiering for datasets
  * S3 Transfer Acceleration for global uploads
  * DataSync for on-premise transfers
- Data Lifecycle:
  * Hot tier: FSx Lustre scratch
  * Warm tier: FSx Lustre persistent
  * Cold tier: S3 Standard
  * Archive: S3 Glacier Deep Archive

Interconnect Architecture:
- On-Premise Connectivity:
  * AWS Direct Connect: 2x 10 Gbps (redundant)
  * Virtual Interfaces (VIFs) with BGP
  * Direct Connect Gateway for multi-region
  * Site-to-Site VPN as backup (Transit Gateway)
- Inter-Region Connectivity:
  * Transit Gateway peering between regions
  * Inter-Region VPC Peering as backup
  * CloudFront for global data distribution
  * AWS Global Accelerator for user access
- Partner Networks:
  * Internet2 connectivity for research networks
  * ESnet integration for DOE laboratories
  * GÉANT for European research networks
  * Private VIFs for partner organizations

Job Scheduling & Orchestration:
- Slurm Configuration:
  * Slurm 23.x with REST API
  * Federation support for multi-cluster
  * Fair-share scheduling with QoS
  * Preemptible queues for spot instances
  * Job arrays and dependencies
  * Accounting with slurmdbd
- Resource Management:
  * GRES for GPU scheduling
  * Cgroups for resource isolation
  * PAM integration for SSH access
  * Prolog/Epilog scripts for setup
  * Power saving with node suspend
- Integration:
  * Open OnDemand for web portal
  * Jupyter Hub for interactive computing
  * Module system (Lmod) for software
  * Singularity/Apptainer for containers

Security & Compliance:
- Network Security:
  * Security groups with minimal access
  * NACLs for subnet-level control
  * AWS Network Firewall for egress filtering
  * GuardDuty for threat detection
  * VPC Flow Logs to S3 for analysis
- Access Control:
  * AWS Systems Manager Session Manager (no SSH)
  * SAML federation with university IdP
  * MFA required for all users
  * IAM roles for EC2 instances
  * Secrets Manager for credentials
- Encryption:
  * EBS encryption with KMS CMK
  * S3 encryption with SSE-S3
  * FSx encryption at rest
  * TLS 1.3 for data in transit
  * AWS Certificate Manager for certs
- Compliance:
  * NIST 800-171 for controlled data
  * ITAR compliance for export control
  * HIPAA for biomedical research
  * CloudTrail for audit logging
  * AWS Config for compliance monitoring

Monitoring & Observability:
- Performance Monitoring:
  * CloudWatch custom metrics (1-minute resolution)
  * EFA network metrics and counters
  * FSx CloudWatch metrics
  * Instance-level network metrics
  * Application-level MPI statistics
- HPC-Specific Monitoring:
  * Ganglia for cluster monitoring
  * Grafana dashboards with Prometheus
  * Custom metrics for job efficiency
  * Network congestion monitoring
  * Storage I/O pattern analysis
- Logging:
  * CloudWatch Logs for system logs
  * Centralized Slurm logging
  * Application logs to S3
  * VPC Flow Logs analysis
  * AWS X-Ray for distributed tracing

Cost Optimization:
- Instance Strategy:
  * Spot Fleet with diversified instance types
  * Savings Plans for baseline capacity
  * Reserved Instances for head nodes
  * Automatic instance type selection
  * Spot interruption handling with checkpointing
- Storage Optimization:
  * S3 Lifecycle policies
  * FSx data compression
  * Intelligent-Tiering for S3
  * EBS snapshot management
  * Data deduplication where possible
- Network Optimization:
  * VPC Endpoints to reduce NAT costs
  * Direct Connect for predictable pricing
  * CloudFront for frequently accessed data
  * Regional data locality
  * Bandwidth pooling

INFRASTRUCTURE AS CODE:
- IaC Tool: Terragrunt 0.50+ with Terraform 1.5+
- Module Source: Terraform Registry (official AWS modules) + custom HPC modules
- Folder Structure:
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
  ├── dev/
  │   ├── account.hcl
  │   ├── env.hcl
  │   └── us-east-2/
  │       ├── region.hcl
  │       ├── networking/
  │       │   ├── vpc/
  │       │   │   └── terragrunt.hcl
  │       │   ├── efa-sg/             # EFA security groups
  │       │   │   └── terragrunt.hcl
  │       │   ├── transit-gateway/
  │       │   │   └── terragrunt.hcl
  │       │   └── direct-connect/
  │       │       └── terragrunt.hcl
  │       ├── compute/
  │       │   ├── parallel-cluster/
  │       │   │   └── terragrunt.hcl
  │       │   ├── batch-compute/       # AWS Batch for overflow
  │       │   │   └── terragrunt.hcl
  │       │   └── ec2-fleet/          # Spot Fleet config
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
  │       │   ├── scheduler/          # Slurm head node
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
  ├── staging/
  │   └── [similar structure]
  └── production/
      ├── us-east-2/
      ├── eu-west-1/
      └── ap-northeast-1/
  ```
- State Backend: S3 with DynamoDB locking, versioning enabled
- Configuration Management: AWS Systems Manager Parameter Store

CI/CD REQUIREMENTS:
- Platform: GitHub Actions with self-hosted runners in private subnet
- Workflow Configuration:
  ```yaml
  name: HPC Infrastructure Deployment
  
  on:
    push:
      branches: [main, develop]
      paths:
        - 'infrastructure/**'
        - 'cluster-configs/**'
    pull_request:
      types: [opened, synchronize, reopened]
    schedule:
      - cron: '0 2 * * *'  # Daily validation
    workflow_dispatch:
      inputs:
        environment:
          type: choice
          options: [dev, staging, production]
        action:
          type: choice
          options: [plan, apply, destroy, scale-up, scale-down]
        cluster_size:
          type: string
          description: 'Target cluster size (for scaling actions)'
  
  env:
    TF_VERSION: '1.5.7'
    TG_VERSION: '0.50.17'
    PCLUSTER_VERSION: '3.7.0'
  
  jobs:
    validate-network:
      runs-on: self-hosted
      steps:
        - name: Validate Network Configuration
          run: |
            # Check EFA compatibility
            # Validate placement groups
            # Verify security groups
            # Test VPC endpoints
            
    validate-storage:
      runs-on: self-hosted
      steps:
        - name: Validate Storage Configuration
          run: |
            # Check FSx configuration
            # Validate S3 buckets
            # Test DataSync tasks
            
    deploy-infrastructure:
      needs: [validate-network, validate-storage]
      runs-on: self-hosted
      strategy:
        matrix:
          component: [networking, storage, compute, monitoring]
      steps:
        - name: Deploy ${{ matrix.component }}
          run: |
            cd infrastructure/${{ inputs.environment }}/us-east-2/${{ matrix.component }}
            terragrunt init
            terragrunt plan -out=tfplan
            terragrunt apply tfplan
            
    deploy-cluster:
      needs: deploy-infrastructure
      runs-on: self-hosted
      steps:
        - name: Deploy ParallelCluster
          run: |
            pcluster create-cluster \
              --cluster-name hpc-${{ inputs.environment }} \
              --cluster-configuration cluster-configs/${{ inputs.environment }}.yaml
              
    test-cluster:
      needs: deploy-cluster
      runs-on: self-hosted
      steps:
        - name: Run HPC Tests
          run: |
            # Test MPI communication
            # Verify EFA functionality
            # Test storage performance
            # Validate job submission
            
    benchmark-network:
      needs: test-cluster
      runs-on: self-hosted
      steps:
        - name: Network Performance Tests
          run: |
            # OSU Micro-Benchmarks
            # Intel MPI Benchmarks
            # EFA diagnostics
            # Bandwidth testing
  ```
- Testing Strategy:
  * Network latency tests with OSU micro-benchmarks
  * Storage performance with IOR and MDtest
  * MPI communication tests
  * Job submission and scheduling tests
  * Failover and recovery tests
  * Cost analysis and optimization
- Deployment Features:
  * Blue-green deployment for cluster updates
  * Automatic rollback on performance degradation
  * Canary deployments for new instance types
  * Progressive rollout of configuration changes

CONSTRAINTS:
- Budget: $200,000/month with automatic scaling limits
- Performance: 
  * Network latency < 15 microseconds for MPI
  * Storage throughput > 10 GB/s aggregate
  * Job queue time < 5 minutes average
- Availability: 99.9% for head node, 99% for compute
- Scalability: Support 10x burst capacity
- Security: NIST 800-171 compliance required
- Data Residency: Research data must stay in origin region

SPECIAL REQUIREMENTS:
- Integration with existing LDAP/AD for authentication
- Support for licensed software (ANSYS, MATLAB, etc.)
- Containerized workload support (Singularity/Docker)
- Hybrid cloud burst to on-premise when needed
- Research data management with metadata tracking
- Job cost attribution per research group
- Automated report generation for grant compliance
- Integration with Globus for data transfer
- Support for interactive jobs and remote visualization
- Checkpointing support for long-running jobs
- Fair-share scheduling with group quotas
- Software module management with EasyBuild/Spack
- Integration with research workflow managers (Nextflow, CWL)

OUTPUT FORMAT:
Please provide:

1. Complete Terragrunt configuration files for all components with:
   - VPC with EFA-optimized networking
   - Security groups for HPC traffic patterns
   - FSx Lustre file systems with optimal settings
   - ParallelCluster configuration YAML
   - Direct Connect and Transit Gateway setup
   - VPC Endpoints for all AWS services

2. GitHub Actions workflows:
   - .github/workflows/hpc-deploy.yml (main deployment)
   - .github/workflows/hpc-validate.yml (configuration validation)
   - .github/workflows/cluster-scaling.yml (auto-scaling management)
   - .github/workflows/performance-test.yml (benchmarking)
   - .github/workflows/cost-analysis.yml (budget monitoring)
   - .github/workflows/dr-failover.yml (disaster recovery)

3. ParallelCluster configuration:
   - cluster-configs/dev.yaml
   - cluster-configs/staging.yaml  
   - cluster-configs/production.yaml
   - Custom bootstrap scripts
   - Slurm configuration files
   - Prolog/Epilog scripts

4. Network optimization configs:
   - EFA configuration scripts
   - Kernel tuning parameters
   - Security group rules for MPI traffic
   - Placement group strategies
   - Network performance tuning

5. Storage configuration:
   - FSx Lustre optimization parameters
   - S3 lifecycle policies
   - DataSync task definitions
   - Backup and snapshot policies
   - Data migration scripts

6. Monitoring and alerting:
   - CloudWatch dashboards for HPC metrics
   - Custom metrics for MPI performance
   - Network utilization monitoring
   - Storage I/O tracking
   - Job efficiency metrics
   - Cost tracking per research group

7. Security configurations:
   - IAM roles and policies
   - KMS key configurations
   - Network ACLs
   - VPC Flow Log analysis queries
   - Compliance checking scripts

8. Performance testing suite:
   - MPI benchmark configurations
   - Network performance tests
   - Storage benchmark scripts
   - Scaling test scenarios
   - Load testing configurations

9. Operational documentation:
   - Network architecture diagrams
   - Data flow diagrams
   - Troubleshooting guide
   - Performance tuning guide
   - Disaster recovery runbook
   - User onboarding guide

10. Cost optimization:
    - Spot Fleet configurations
    - Reserved Instance recommendations
    - Savings Plan analysis
    - Usage reports and dashboards
    - Budget alerts and controls
```

---

## Alternative Focused Prompts

### 1. Minimal HPC Networking Setup

```
Create a Terragrunt deployment for a basic HPC networking setup on AWS:

REQUIREMENTS:
- Single region (us-east-2) with 100-node cluster capacity
- EFA-enabled instances (c5n.18xlarge)
- FSx Lustre (100TB scratch)
- Slurm scheduler with ParallelCluster
- VPC with cluster placement groups
- GitHub Actions for deployment

Focus on network optimization for MPI workloads with <20 microsecond latency.
```

### 2. Multi-Region HPC Network

```
Create a Terraform deployment for a globally distributed HPC network on AWS:

REQUIREMENTS:
- Regions: us-east-1, eu-central-1, ap-southeast-2
- 500 nodes per region with EFA
- Inter-region connectivity via Transit Gateway
- Global FSx Lustre with S3 backing
- Centralized job scheduling
- Direct Connect to each region
- GitHub Actions with region-specific deployments

Optimize for collaborative research with data locality and minimal inter-region latency.
```

### 3. Hybrid HPC Network

```
Create a Terragrunt deployment for hybrid cloud HPC on AWS:

REQUIREMENTS:
- AWS Outposts for on-premise integration
- Burst capability to AWS cloud (1000 nodes)
- Direct Connect with dedicated bandwidth
- Hybrid file system (on-prem NFS + FSx)
- Unified job scheduler across hybrid infrastructure
- Network optimization for hybrid MPI jobs
- GitHub Actions for hybrid deployments

Focus on seamless workload migration between on-premise and cloud.
```

### 4. GPU-Focused HPC Network

```
Create a Terraform deployment for GPU-accelerated HPC on AWS:

REQUIREMENTS:
- P4d.24xlarge instances (8x A100 GPUs)
- GPUDirect RDMA over EFA
- High-bandwidth storage (FSx Lustre 2.4GB/s/TiB)
- NCCL-optimized networking
- Multi-node GPU training support
- GitHub Actions with GPU testing

Optimize for distributed deep learning and GPU-accelerated simulations.
```

### 5. Cost-Optimized HPC Network

```
Create a Terragrunt deployment for cost-optimized HPC on AWS:

REQUIREMENTS:
- 90% Spot instances with interruption handling
- Automatic instance type selection
- Checkpointing for long jobs
- S3-backed FSx Lustre (archive tier)
- Intelligent scaling based on queue depth
- Network optimization within budget
- GitHub Actions with cost tracking

Target: 50% cost reduction while maintaining performance.
```

---

## Key HPC Networking Considerations

### Critical Network Components
1. **Elastic Fabric Adapter (EFA)** - Kernel bypass for ultra-low latency
2. **Cluster Placement Groups** - Physical proximity for minimal latency
3. **Enhanced Networking (SR-IOV)** - High packet-per-second performance
4. **Jumbo Frames** - Reduced overhead for large transfers
5. **Single AZ Deployment** - Eliminate inter-AZ latency

### Performance Targets
- **MPI Latency**: < 15 microseconds
- **Bandwidth**: 100 Gbps per node
- **Storage Throughput**: > 10 GB/s aggregate
- **Job Startup**: < 30 seconds
- **Scaling Time**: < 5 minutes

### Best Practices
1. Use dedicated instance types (C5n, M5n, M5dn)
2. Disable hyperthreading for consistent performance
3. Pin processes to cores for NUMA optimization
4. Use cluster placement groups with partition strategy
5. Implement proper MPI tuning (ranks, OpenMP threads)
6. Monitor network congestion and retransmissions
7. Optimize storage striping for parallel I/O

This comprehensive prompt will generate a complete HPC networking infrastructure optimized for scientific computing workloads with ultra-low latency and high bandwidth requirements.