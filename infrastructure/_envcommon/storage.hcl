# Shared Storage Configuration for HPC Infrastructure
locals {
  # FSx Lustre Configuration
  fsx_lustre_config = {
    # Scratch filesystem for temporary data
    scratch = {
      storage_capacity = 500  # TB
      storage_type = "SSD"
      deployment_type = "PERSISTENT_1"
      per_unit_storage_throughput = 200  # MB/s per TiB
      data_compression_type = "LZ4"
      auto_import_policy = "NEW_CHANGED_DELETED"
      automatic_backup_retention_days = 7
      daily_automatic_backup_start_time = "03:00"
      weekly_maintenance_start_time = "sun:04:00"
      tags = {
        Purpose = "Scratch-Storage"
        Environment = local.environment
        DataLifecycle = "Temporary"
      }
    }
    
    # Persistent filesystem for long-term data
    persistent = {
      storage_capacity = 100  # TB
      storage_type = "SSD"
      deployment_type = "PERSISTENT_1"
      per_unit_storage_throughput = 1000  # MB/s per TiB
      data_compression_type = "LZ4"
      auto_import_policy = "NEW_CHANGED_DELETED"
      automatic_backup_retention_days = 30
      daily_automatic_backup_start_time = "03:00"
      weekly_maintenance_start_time = "sun:04:00"
      tags = {
        Purpose = "Persistent-Storage"
        Environment = local.environment
        DataLifecycle = "Long-term"
      }
    }
  }
  
  # S3 Configuration for data repository
  s3_config = {
    data_repository = {
      bucket_name = "hpc-data-repository-${local.environment}-${random_id.bucket_suffix.hex}"
      versioning_enabled = true
      encryption_enabled = true
      encryption_algorithm = "AES256"
      lifecycle_rules = [
        {
          id = "transition_to_ia"
          enabled = true
          transition = [
            {
              days = 30
              storage_class = "STANDARD_IA"
            }
          ]
        },
        {
          id = "transition_to_glacier"
          enabled = true
          transition = [
            {
              days = 90
              storage_class = "GLACIER"
            }
          ]
        },
        {
          id = "transition_to_deep_archive"
          enabled = true
          transition = [
            {
              days = 365
              storage_class = "DEEP_ARCHIVE"
            }
          ]
        }
      ]
      intelligent_tiering = {
        enabled = true
        status = "Enabled"
      }
    }
    
    # S3 bucket for VPC Flow Logs
    flow_logs = {
      bucket_name = "hpc-vpc-flow-logs-${local.environment}-${random_id.bucket_suffix.hex}"
      versioning_enabled = true
      encryption_enabled = true
      lifecycle_rules = [
        {
          id = "delete_old_logs"
          enabled = true
          expiration = {
            days = 90
          }
        }
      ]
    }
    
    # S3 bucket for CloudWatch Logs
    cloudwatch_logs = {
      bucket_name = "hpc-cloudwatch-logs-${local.environment}-${random_id.bucket_suffix.hex}"
      versioning_enabled = true
      encryption_enabled = true
      lifecycle_rules = [
        {
          id = "transition_to_ia"
          enabled = true
          transition = [
            {
              days = 30
              storage_class = "STANDARD_IA"
            }
          ]
        },
        {
          id = "delete_old_logs"
          enabled = true
          expiration = {
            days = 365
          }
        }
      ]
    }
  }
  
  # EFS Configuration for home directories
  efs_config = {
    home_directories = {
      performance_mode = "generalPurpose"
      throughput_mode = "provisioned"
      provisioned_throughput_in_mibps = 1000
      encrypted = true
      kms_key_id = "alias/hpc-efs-key"
      lifecycle_policy = {
        transition_to_ia = "AFTER_30_DAYS"
        transition_to_primary_storage_class = "AFTER_1_ACCESS"
      }
      backup_policy = {
        status = "ENABLED"
      }
      tags = {
        Purpose = "Home-Directories"
        Environment = local.environment
      }
    }
  }
  
  # EBS Configuration for local storage
  ebs_config = {
    # High-performance EBS volumes for compute nodes
    compute_storage = {
      volume_type = "io2"
      iops = 256000
      throughput = 4000  # MB/s
      size = 1000  # GB
      encrypted = true
      kms_key_id = "alias/hpc-ebs-key"
      multi_attach_enabled = true
      tags = {
        Purpose = "Compute-Local-Storage"
        Environment = local.environment
      }
    }
    
    # Standard EBS volumes for head node
    head_node_storage = {
      volume_type = "gp3"
      iops = 16000
      throughput = 1000  # MB/s
      size = 500  # GB
      encrypted = true
      kms_key_id = "alias/hpc-ebs-key"
      tags = {
        Purpose = "Head-Node-Storage"
        Environment = local.environment
      }
    }
  }
  
  # DataSync Configuration for on-premise connectivity
  datasync_config = {
    source_location = {
      type = "SMB"
      agent_arns = ["arn:aws:datasync:us-east-2:${data.aws_caller_identity.current.account_id}:agent/agent-0123456789abcdef0"]
      subdirectory = "/hpc-data"
      domain = "example.com"
      user = "datasync-user"
      password = "datasync-password"
      tags = {
        Purpose = "On-Premise-Sync"
        Environment = local.environment
      }
    }
    
    destination_location = {
      type = "S3"
      s3_bucket_arn = "arn:aws:s3:::${local.s3_config.data_repository.bucket_name}"
      subdirectory = "/on-premise-sync"
      s3_config = {
        bucket_access_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/DataSyncS3Role"
      }
      tags = {
        Purpose = "On-Premise-Sync"
        Environment = local.environment
      }
    }
    
    task = {
      source_location_arn = "arn:aws:datasync:us-east-2:${data.aws_caller_identity.current.account_id}:location/loc-0123456789abcdef0"
      destination_location_arn = "arn:aws:datasync:us-east-2:${data.aws_caller_identity.current.account_id}:location/loc-0123456789abcdef1"
      name = "hpc-on-premise-sync"
      options = {
        verify_mode = "POINT_IN_TIME_CONSISTENT"
        overwrite_mode = "ALWAYS"
        atime = "BEST_EFFORT"
        mtime = "PRESERVE"
        uid = "INT_VALUE"
        gid = "INT_VALUE"
        preserve_deleted_files = "PRESERVE"
        preserve_devices = "NONE"
        posix_permissions = "NONE"
        bytes_per_second = -1
        task_queueing = "ENABLED"
        log_level = "TRANSFER"
        transfer_mode = "CHANGED"
        security_descriptor_copy_flags = "NONE"
        object_tags = "PRESERVE"
      }
      tags = {
        Purpose = "On-Premise-Sync"
        Environment = local.environment
      }
    }
  }
  
  # Backup Configuration
  backup_config = {
    vault_name = "hpc-backup-vault-${local.environment}"
    vault_kms_key_arn = "arn:aws:kms:us-east-2:${data.aws_caller_identity.current.account_id}:key/hpc-backup-key"
    
    # FSx Lustre backup plan
    fsx_backup_plan = {
      name = "hpc-fsx-backup-plan"
      rules = [
        {
          rule_name = "daily_backup"
          target_vault_name = "hpc-backup-vault-${local.environment}"
          schedule = "cron(0 2 * * ? *)"  # Daily at 2 AM
          start_window = 60  # minutes
          completion_window = 300  # minutes
          lifecycle = {
            cold_storage_after = 30  # days
            delete_after = 90  # days
          }
          recovery_point_tags = {
            Environment = local.environment
            BackupType = "FSx-Lustre"
          }
        }
      ]
    }
    
    # EBS backup plan
    ebs_backup_plan = {
      name = "hpc-ebs-backup-plan"
      rules = [
        {
          rule_name = "daily_ebs_backup"
          target_vault_name = "hpc-backup-vault-${local.environment}"
          schedule = "cron(0 3 * * ? *)"  # Daily at 3 AM
          start_window = 60  # minutes
          completion_window = 300  # minutes
          lifecycle = {
            cold_storage_after = 7  # days
            delete_after = 30  # days
          }
          recovery_point_tags = {
            Environment = local.environment
            BackupType = "EBS"
          }
        }
      ]
    }
  }
}
