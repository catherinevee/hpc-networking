# Shared HPC Cluster Configuration
locals {
  # Cluster naming convention
  cluster_name = "hpc-${local.environment}"
  
  # Instance type mappings for different workloads
  instance_types = {
    compute = {
      hpc_optimized = "hpc6a.48xlarge"  # 96 vCPUs, 384 GiB RAM, 100 Gbps EFA
      memory_optimized = "x2iezn.32xlarge"  # 128 vCPUs, 4 TiB RAM
      gpu_instances = "p4d.24xlarge"  # 8x A100 GPUs
      general_purpose = "m6i.32xlarge"  # 128 vCPUs, 512 GiB RAM
    }
    spot_types = [
      "hpc6a.48xlarge",
      "c5n.18xlarge",
      "c5n.24xlarge",
      "c5n.9xlarge",
      "m5n.24xlarge",
      "m5dn.24xlarge"
    ]
  }
  
  # Queue configurations for Slurm
  slurm_queues = {
    compute = {
      instance_types = ["hpc6a.48xlarge", "c5n.18xlarge"]
      min_count = 0
      max_count = 500
      spot_percentage = 70
    }
    memory = {
      instance_types = ["x2iezn.32xlarge", "r5n.24xlarge"]
      min_count = 0
      max_count = 100
      spot_percentage = 50
    }
    gpu = {
      instance_types = ["p4d.24xlarge", "p3.16xlarge"]
      min_count = 0
      max_count = 50
      spot_percentage = 60
    }
    debug = {
      instance_types = ["c5n.large", "m5n.large"]
      min_count = 1
      max_count = 10
      spot_percentage = 0
    }
  }
  
  # EFA configuration
  efa_config = {
    enabled = true
    instance_types = local.instance_types.spot_types
    security_group_rules = {
      efa_ports = {
        from_port = 2049
        to_port = 2049
        protocol = "tcp"
        description = "EFA communication"
      }
      mpi_ports = {
        from_port = 1024
        to_port = 65535
        protocol = "tcp"
        description = "MPI communication"
      }
    }
  }
  
  # Placement group configuration
  placement_groups = {
    compute = {
      strategy = "cluster"
      partition_count = 3
    }
    storage = {
      strategy = "partition"
      partition_count = 2
    }
  }
  
  # Auto-scaling configuration
  auto_scaling = {
    scale_down_cooldown = 300  # 5 minutes
    scale_up_cooldown = 60     # 1 minute
    max_nodes_per_az = 100
    min_nodes_per_az = 0
    target_capacity = 80  # percentage
  }
}
