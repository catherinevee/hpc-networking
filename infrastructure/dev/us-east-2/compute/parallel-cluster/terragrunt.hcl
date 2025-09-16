# AWS ParallelCluster Configuration for Dev Environment
include "region" {
  path = "../../region.hcl"
}

terraform {
  source = "git::https://github.com/aws-ia/terraform-aws-parallelcluster.git?ref=v3.7.0"
}

# Dependencies
dependency "vpc" {
  config_path = "../../networking/vpc"
}

dependency "efa_sg" {
  config_path = "../../networking/efa-sg"
}

dependency "fsx_scratch" {
  config_path = "../../storage/fsx-lustre-scratch"
}

dependency "fsx_persistent" {
  config_path = "../../storage/fsx-lustre-persistent"
}

inputs = {
  # Cluster Configuration
  cluster_name = "hpc-${local.environment}"
  cluster_version = "3.7.0"
  
  # VPC Configuration
  vpc_id = dependency.vpc.outputs.vpc_id
  compute_subnet_id = dependency.vpc.outputs.compute_subnets[0]
  head_node_subnet_id = dependency.vpc.outputs.public_subnets[0]
  
  # Head Node Configuration
  head_node = {
    instance_type = "c5n.2xlarge"
    ami_id = data.aws_ami.hpc_optimized.id
    
    # Storage
    root_volume = {
      size = 100
      volume_type = "gp3"
      iops = 3000
      throughput = 125
      encrypted = true
    }
    
    # Additional storage
    custom_ami = {
      ami_id = data.aws_ami.hpc_optimized.id
    }
    
    # Security groups
    security_groups = [
      dependency.efa_sg.outputs.security_group_id
    ]
    
    # IAM role
    iam_role = aws_iam_role.head_node.name
    
    # User data
    custom_ami = {
      ami_id = data.aws_ami.hpc_optimized.id
    }
  }
  
  # Compute Nodes Configuration
  compute_nodes = {
    # Compute queue
    compute = {
      instance_types = [local.instance_types.compute]
      min_count = 0
      max_count = 50
      spot_price = 0.5  # $0.50 per hour max
      
      # EFA configuration
      efa_enabled = true
      placement_group = {
        enabled = true
        name = dependency.efa_sg.outputs.placement_group_name
      }
      
      # Security groups
      security_groups = [
        dependency.efa_sg.outputs.security_group_id
      ]
      
      # IAM role
      iam_role = aws_iam_role.compute_node.name
      
      # Storage
      root_volume = {
        size = 100
        volume_type = "gp3"
        iops = 3000
        throughput = 125
        encrypted = true
      }
      
      # Additional EBS volumes
      additional_ebs_volumes = [
        {
          volume_id = aws_ebs_volume.compute_storage.id
          mount_dir = "/scratch"
        }
      ]
    }
    
    # Memory queue
    memory = {
      instance_types = [local.instance_types.memory]
      min_count = 0
      max_count = 10
      spot_price = 1.0  # $1.00 per hour max
      
      # EFA configuration
      efa_enabled = true
      placement_group = {
        enabled = true
        name = dependency.efa_sg.outputs.placement_group_name
      }
      
      # Security groups
      security_groups = [
        dependency.efa_sg.outputs.security_group_id
      ]
      
      # IAM role
      iam_role = aws_iam_role.compute_node.name
    }
    
    # GPU queue
    gpu = {
      instance_types = [local.instance_types.gpu]
      min_count = 0
      max_count = 5
      spot_price = 2.0  # $2.00 per hour max
      
      # EFA configuration
      efa_enabled = true
      placement_group = {
        enabled = true
        name = dependency.efa_sg.outputs.placement_group_name
      }
      
      # Security groups
      security_groups = [
        dependency.efa_sg.outputs.security_group_id
      ]
      
      # IAM role
      iam_role = aws_iam_role.compute_node.name
    }
    
    # Debug queue
    debug = {
      instance_types = [local.instance_types.debug]
      min_count = 1
      max_count = 2
      spot_price = 0  # On-demand for debug
      
      # EFA configuration
      efa_enabled = true
      placement_group = {
        enabled = true
        name = dependency.efa_sg.outputs.placement_group_name
      }
      
      # Security groups
      security_groups = [
        dependency.efa_sg.outputs.security_group_id
      ]
      
      # IAM role
      iam_role = aws_iam_role.compute_node.name
    }
  }
  
  # Shared Storage Configuration
  shared_storage = {
    # FSx Lustre scratch
    scratch = {
      storage_type = "FsxLustre"
      mount_dir = "/scratch"
      name = "scratch"
      fsx_lustre_configuration = {
        file_system_id = dependency.fsx_scratch.outputs.file_system_id
        mount_name = dependency.fsx_scratch.outputs.mount_name
      }
    }
    
    # FSx Lustre persistent
    persistent = {
      storage_type = "FsxLustre"
      mount_dir = "/shared"
      name = "persistent"
      fsx_lustre_configuration = {
        file_system_id = dependency.fsx_persistent.outputs.file_system_id
        mount_name = dependency.fsx_persistent.outputs.mount_name
      }
    }
    
    # EFS home directories
    home = {
      storage_type = "Efs"
      mount_dir = "/home"
      name = "home"
      efs_configuration = {
        file_system_id = aws_efs_file_system.home.id
        encrypted = true
      }
    }
  }
  
  # Slurm Configuration
  slurm_settings = {
    # Queue configuration
    queue_settings = {
      compute = {
        compute_resource_settings = {
          min_count = 0
          max_count = 50
          spot_price = 0.5
        }
      }
      memory = {
        compute_resource_settings = {
          min_count = 0
          max_count = 10
          spot_price = 1.0
        }
      }
      gpu = {
        compute_resource_settings = {
          min_count = 0
          max_count = 5
          spot_price = 2.0
        }
      }
      debug = {
        compute_resource_settings = {
          min_count = 1
          max_count = 2
          spot_price = 0
        }
      }
    }
    
    # Scheduling configuration
    scheduling = {
      scheduler = "slurm"
      scaling = {
        min_count = 0
        max_count = 100
        target_capacity = 80
        scale_down_cooldown = 300
        scale_up_cooldown = 60
      }
    }
    
    # Job accounting
    accounting = {
      enabled = true
      database = {
        host = aws_rds_cluster.slurmdbd.endpoint
        port = 3306
        name = "slurm_acct_db"
        user = "slurm"
        password = aws_secretsmanager_secret.slurm_password.arn
      }
    }
  }
  
  # Monitoring Configuration
  monitoring = {
    log_rotation = {
      enabled = true
      max_size = "100M"
      max_files = 10
    }
    
    cloudwatch = {
      enabled = true
      log_group_name = "/aws/parallelcluster/hpc-${local.environment}"
      retention_days = local.monitoring.cloudwatch.log_retention_days
    }
  }
  
  # Tags
  tags = merge(local.common_tags, {
    Component = "ParallelCluster"
    Tier      = "HPC-Compute"
  })
}

# Data source for HPC-optimized AMI
data "aws_ami" "hpc_optimized" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
  
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# IAM Role for Head Node
resource "aws_iam_role" "head_node" {
  name = "hpc-${local.environment}-head-node-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
  
  tags = merge(local.common_tags, {
    Name = "hpc-${local.environment}-head-node-role"
    Type = "IAM-Role"
  })
}

# IAM Role for Compute Nodes
resource "aws_iam_role" "compute_node" {
  name = "hpc-${local.environment}-compute-node-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
  
  tags = merge(local.common_tags, {
    Name = "hpc-${local.environment}-compute-node-role"
    Type = "IAM-Role"
  })
}

# EFS File System for Home Directories
resource "aws_efs_file_system" "home" {
  performance_mode = "generalPurpose"
  throughput_mode  = "provisioned"
  provisioned_throughput_in_mibps = 100
  
  encrypted = true
  kms_key_id = aws_kms_key.hpc.arn
  
  tags = merge(local.common_tags, {
    Name = "hpc-${local.environment}-home-efs"
    Type = "EFS-FileSystem"
  })
}

# EBS Volume for Compute Storage
resource "aws_ebs_volume" "compute_storage" {
  availability_zone = local.networking.primary_az
  size              = 1000
  type              = "gp3"
  iops              = 3000
  throughput        = 125
  encrypted         = true
  kms_key_id        = aws_kms_key.hpc.arn
  
  tags = merge(local.common_tags, {
    Name = "hpc-${local.environment}-compute-storage"
    Type = "EBS-Volume"
  })
}

# RDS Cluster for Slurm Database
resource "aws_rds_cluster" "slurmdbd" {
  cluster_identifier = "hpc-${local.environment}-slurmdbd"
  engine             = "aurora-mysql"
  engine_version     = "8.0.mysql_aurora.3.02.0"
  database_name      = "slurm_acct_db"
  master_username    = "admin"
  master_password    = aws_secretsmanager_secret.slurm_password.arn
  
  backup_retention_period = 7
  preferred_backup_window = "03:00-04:00"
  preferred_maintenance_window = "sun:04:00-sun:05:00"
  
  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.slurmdbd.name
  
  skip_final_snapshot = true
  deletion_protection = false
  
  tags = merge(local.common_tags, {
    Name = "hpc-${local.environment}-slurmdbd"
    Type = "RDS-Cluster"
  })
}

# Secrets Manager Secret for Slurm Password
resource "aws_secretsmanager_secret" "slurm_password" {
  name = "hpc-${local.environment}-slurm-password"
  
  tags = merge(local.common_tags, {
    Name = "hpc-${local.environment}-slurm-password"
    Type = "SecretsManager-Secret"
  })
}

# Security Group for RDS
resource "aws_security_group" "rds" {
  name_prefix = "hpc-${local.environment}-rds-"
  vpc_id      = dependency.vpc.outputs.vpc_id
  description = "Security group for Slurm database"
  
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [local.networking.vpc_cidr]
    description = "MySQL access from VPC"
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }
  
  tags = merge(local.common_tags, {
    Name = "hpc-${local.environment}-rds-sg"
    Type = "RDS-SecurityGroup"
  })
  
  lifecycle {
    create_before_destroy = true
  }
}

# DB Subnet Group for RDS
resource "aws_db_subnet_group" "slurmdbd" {
  name       = "hpc-${local.environment}-slurmdbd"
  subnet_ids = dependency.vpc.outputs.database_subnets
  
  tags = merge(local.common_tags, {
    Name = "hpc-${local.environment}-slurmdbd-subnet-group"
    Type = "DB-SubnetGroup"
  })
}
