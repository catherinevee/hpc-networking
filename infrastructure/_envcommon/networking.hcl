# Shared Networking Configuration for HPC Infrastructure
locals {
  # VPC Configuration
  vpc_config = {
    cidr_block = "10.0.0.0/16"
    enable_dns_hostnames = true
    enable_dns_support = true
    enable_classiclink = false
    enable_classiclink_dns_support = false
    instance_tenancy = "default"
  }
  
  # Subnet Configuration
  subnet_config = {
    public = {
      cidr_blocks = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
      map_public_ip_on_launch = true
      availability_zones = ["us-east-2a", "us-east-2b", "us-east-2c"]
    }
    private = {
      cidr_blocks = ["10.0.10.0/24", "10.0.20.0/24", "10.0.30.0/24"]
      map_public_ip_on_launch = false
      availability_zones = ["us-east-2a", "us-east-2b", "us-east-2c"]
    }
    compute = {
      cidr_blocks = ["10.0.100.0/22", "10.0.104.0/22", "10.0.108.0/22"]
      map_public_ip_on_launch = false
      availability_zones = ["us-east-2a", "us-east-2b", "us-east-2c"]
    }
    storage = {
      cidr_blocks = ["10.0.200.0/24", "10.0.201.0/24", "10.0.202.0/24"]
      map_public_ip_on_launch = false
      availability_zones = ["us-east-2a", "us-east-2b", "us-east-2c"]
    }
  }
  
  # Security Group Rules
  security_groups = {
    # EFA Security Group for MPI communication
    efa = {
      name = "hpc-efa-sg"
      description = "Security group for EFA-enabled instances"
      ingress_rules = [
        {
          from_port = 2049
          to_port = 2049
          protocol = "tcp"
          cidr_blocks = [local.vpc_config.cidr_block]
          description = "EFA communication"
        },
        {
          from_port = 1024
          to_port = 65535
          protocol = "tcp"
          cidr_blocks = [local.vpc_config.cidr_block]
          description = "MPI communication"
        },
        {
          from_port = 0
          to_port = 0
          protocol = "-1"
          self = true
          description = "All traffic within security group"
        }
      ]
      egress_rules = [
        {
          from_port = 0
          to_port = 0
          protocol = "-1"
          cidr_blocks = ["0.0.0.0/0"]
          description = "All outbound traffic"
        }
      ]
    }
    
    # Head Node Security Group
    head_node = {
      name = "hpc-head-node-sg"
      description = "Security group for Slurm head node"
      ingress_rules = [
        {
          from_port = 22
          to_port = 22
          protocol = "tcp"
          cidr_blocks = ["10.0.0.0/8"]
          description = "SSH access"
        },
        {
          from_port = 6817
          to_port = 6817
          protocol = "tcp"
          cidr_blocks = [local.vpc_config.cidr_block]
          description = "Slurm controller"
        },
        {
          from_port = 6818
          to_port = 6818
          protocol = "tcp"
          cidr_blocks = [local.vpc_config.cidr_block]
          description = "Slurm database"
        },
        {
          from_port = 8080
          to_port = 8080
          protocol = "tcp"
          cidr_blocks = [local.vpc_config.cidr_block]
          description = "Open OnDemand"
        }
      ]
    }
    
    # Compute Node Security Group
    compute_node = {
      name = "hpc-compute-node-sg"
      description = "Security group for compute nodes"
      ingress_rules = [
        {
          from_port = 22
          to_port = 22
          protocol = "tcp"
          cidr_blocks = [local.vpc_config.cidr_block]
          description = "SSH access from head node"
        },
        {
          from_port = 0
          to_port = 0
          protocol = "-1"
          source_security_group_id = "hpc-efa-sg"
          description = "All traffic from EFA security group"
        }
      ]
    }
    
    # Storage Security Group
    storage = {
      name = "hpc-storage-sg"
      description = "Security group for storage systems"
      ingress_rules = [
        {
          from_port = 2049
          to_port = 2049
          protocol = "tcp"
          cidr_blocks = [local.vpc_config.cidr_block]
          description = "NFS access"
        },
        {
          from_port = 111
          to_port = 111
          protocol = "tcp"
          cidr_blocks = [local.vpc_config.cidr_block]
          description = "RPC portmapper"
        },
        {
          from_port = 20048
          to_port = 20048
          protocol = "tcp"
          cidr_blocks = [local.vpc_config.cidr_block]
          description = "Lustre MGS"
        }
      ]
    }
  }
  
  # VPC Endpoints for AWS services
  vpc_endpoints = {
    s3 = {
      service = "s3"
      vpc_endpoint_type = "Gateway"
      route_table_ids = ["private_route_table_ids"]
    }
    ec2 = {
      service = "ec2"
      vpc_endpoint_type = "Interface"
      subnet_ids = ["private_subnet_ids"]
      security_group_ids = ["vpc_endpoint_sg"]
    }
    ec2messages = {
      service = "ec2messages"
      vpc_endpoint_type = "Interface"
      subnet_ids = ["private_subnet_ids"]
      security_group_ids = ["vpc_endpoint_sg"]
    }
    ssm = {
      service = "ssm"
      vpc_endpoint_type = "Interface"
      subnet_ids = ["private_subnet_ids"]
      security_group_ids = ["vpc_endpoint_sg"]
    }
    ssmmessages = {
      service = "ssmmessages"
      vpc_endpoint_type = "Interface"
      subnet_ids = ["private_subnet_ids"]
      security_group_ids = ["vpc_endpoint_sg"]
    }
    cloudwatch = {
      service = "cloudwatch"
      vpc_endpoint_type = "Interface"
      subnet_ids = ["private_subnet_ids"]
      security_group_ids = ["vpc_endpoint_sg"]
    }
    cloudwatchlogs = {
      service = "logs"
      vpc_endpoint_type = "Interface"
      subnet_ids = ["private_subnet_ids"]
      security_group_ids = ["vpc_endpoint_sg"]
    }
  }
  
  # Transit Gateway Configuration
  transit_gateway = {
    description = "HPC Networking Transit Gateway"
    amazon_side_asn = 64512
    auto_accept_shared_attachments = "disable"
    default_route_table_association = "enable"
    default_route_table_propagation = "enable"
    dns_support = "enable"
    vpn_ecmp_support = "enable"
  }
  
  # Direct Connect Configuration
  direct_connect = {
    bandwidth = "10Gbps"
    location = "AWS Direct Connect Location"
    tags = {
      Environment = local.environment
      Purpose = "HPC-Connectivity"
    }
  }
}
