# Shared Monitoring Configuration for HPC Infrastructure
locals {
  # CloudWatch Configuration
  cloudwatch_config = {
    log_groups = {
      hpc_system_logs = {
        name = "/aws/hpc/${local.environment}/system"
        retention_in_days = 30
        kms_key_id = "alias/hpc-cloudwatch-key"
      }
      slurm_logs = {
        name = "/aws/hpc/${local.environment}/slurm"
        retention_in_days = 90
        kms_key_id = "alias/hpc-cloudwatch-key"
      }
      mpi_logs = {
        name = "/aws/hpc/${local.environment}/mpi"
        retention_in_days = 30
        kms_key_id = "alias/hpc-cloudwatch-key"
      }
      application_logs = {
        name = "/aws/hpc/${local.environment}/applications"
        retention_in_days = 60
        kms_key_id = "alias/hpc-cloudwatch-key"
      }
      vpc_flow_logs = {
        name = "/aws/vpc/flowlogs/${local.environment}"
        retention_in_days = 30
        kms_key_id = "alias/hpc-cloudwatch-key"
      }
    }
    
    # Custom metrics for HPC workloads
    custom_metrics = {
      job_efficiency = {
        namespace = "HPC/Jobs"
        metric_name = "JobEfficiency"
        statistic = "Average"
        period = 300  # 5 minutes
        unit = "Percent"
      }
      mpi_latency = {
        namespace = "HPC/Network"
        metric_name = "MPILatency"
        statistic = "Average"
        period = 60  # 1 minute
        unit = "Microseconds"
      }
      storage_throughput = {
        namespace = "HPC/Storage"
        metric_name = "StorageThroughput"
        statistic = "Sum"
        period = 60  # 1 minute
        unit = "Bytes/Second"
      }
      queue_depth = {
        namespace = "HPC/Scheduler"
        metric_name = "QueueDepth"
        statistic = "Maximum"
        period = 60  # 1 minute
        unit = "Count"
      }
      node_utilization = {
        namespace = "HPC/Compute"
        metric_name = "NodeUtilization"
        statistic = "Average"
        period = 300  # 5 minutes
        unit = "Percent"
      }
    }
    
    # Alarms for critical metrics
    alarms = {
      high_queue_depth = {
        alarm_name = "hpc-high-queue-depth-${local.environment}"
        comparison_operator = "GreaterThanThreshold"
        evaluation_periods = 2
        metric_name = "QueueDepth"
        namespace = "HPC/Scheduler"
        period = 300
        statistic = "Average"
        threshold = 100
        alarm_description = "High queue depth detected"
        alarm_actions = ["arn:aws:sns:us-east-2:${data.aws_caller_identity.current.account_id}:hpc-alerts"]
        ok_actions = ["arn:aws:sns:us-east-2:${data.aws_caller_identity.current.account_id}:hpc-alerts"]
        treat_missing_data = "notBreaching"
      }
      
      low_storage_space = {
        alarm_name = "hpc-low-storage-space-${local.environment}"
        comparison_operator = "LessThanThreshold"
        evaluation_periods = 1
        metric_name = "FreeStorageSpace"
        namespace = "AWS/FSx"
        period = 300
        statistic = "Average"
        threshold = 1000000000000  # 1TB in bytes
        alarm_description = "Low storage space detected"
        alarm_actions = ["arn:aws:sns:us-east-2:${data.aws_caller_identity.current.account_id}:hpc-alerts"]
        ok_actions = ["arn:aws:sns:us-east-2:${data.aws_caller_identity.current.account_id}:hpc-alerts"]
        treat_missing_data = "notBreaching"
      }
      
      high_mpi_latency = {
        alarm_name = "hpc-high-mpi-latency-${local.environment}"
        comparison_operator = "GreaterThanThreshold"
        evaluation_periods = 3
        metric_name = "MPILatency"
        namespace = "HPC/Network"
        period = 60
        statistic = "Average"
        threshold = 20  # microseconds
        alarm_description = "High MPI latency detected"
        alarm_actions = ["arn:aws:sns:us-east-2:${data.aws_caller_identity.current.account_id}:hpc-alerts"]
        ok_actions = ["arn:aws:sns:us-east-2:${data.aws_caller_identity.current.account_id}:hpc-alerts"]
        treat_missing_data = "notBreaching"
      }
      
      compute_node_failure = {
        alarm_name = "hpc-compute-node-failure-${local.environment}"
        comparison_operator = "GreaterThanThreshold"
        evaluation_periods = 1
        metric_name = "NodeFailureRate"
        namespace = "HPC/Compute"
        period = 300
        statistic = "Average"
        threshold = 5  # percent
        alarm_description = "High compute node failure rate"
        alarm_actions = ["arn:aws:sns:us-east-2:${data.aws_caller_identity.current.account_id}:hpc-alerts"]
        ok_actions = ["arn:aws:sns:us-east-2:${data.aws_caller_identity.current.account_id}:hpc-alerts"]
        treat_missing_data = "notBreaching"
      }
    }
  }
  
  # Grafana Configuration
  grafana_config = {
    workspace_name = "hpc-grafana-${local.environment}"
    account_access_type = "CURRENT_ACCOUNT"
    authentication_providers = ["SAML"]
    permission_type = "SERVICE_MANAGED"
    role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/GrafanaServiceRole"
    
    # Data sources
    data_sources = {
      cloudwatch = {
        name = "CloudWatch"
        type = "cloudwatch"
        access = "proxy"
        json_data = {
          default_region = "us-east-2"
          auth_type = "keys"
          assume_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/GrafanaCloudWatchRole"
        }
      }
      prometheus = {
        name = "Prometheus"
        type = "prometheus"
        access = "proxy"
        url = "http://prometheus-server:9090"
      }
    }
    
    # Dashboards
    dashboards = {
      hpc_overview = {
        title = "HPC Cluster Overview"
        folder = "HPC"
        panels = [
          {
            title = "Job Queue Status"
            type = "stat"
            targets = [
              {
                expr = "slurm_jobs_pending"
                legendFormat = "Pending Jobs"
              },
              {
                expr = "slurm_jobs_running"
                legendFormat = "Running Jobs"
              }
            ]
          },
          {
            title = "Node Utilization"
            type = "graph"
            targets = [
              {
                expr = "avg(slurm_node_cpu_usage)"
                legendFormat = "CPU Usage %"
              },
              {
                expr = "avg(slurm_node_memory_usage)"
                legendFormat = "Memory Usage %"
              }
            ]
          },
          {
            title = "Network Performance"
            type = "graph"
            targets = [
              {
                expr = "avg(mpi_latency_microseconds)"
                legendFormat = "MPI Latency (μs)"
              },
              {
                expr = "avg(network_bandwidth_gbps)"
                legendFormat = "Network Bandwidth (Gbps)"
              }
            ]
          },
          {
            title = "Storage Performance"
            type = "graph"
            targets = [
              {
                expr = "avg(fsx_read_throughput_mbps)"
                legendFormat = "Read Throughput (MB/s)"
              },
              {
                expr = "avg(fsx_write_throughput_mbps)"
                legendFormat = "Write Throughput (MB/s)"
              }
            ]
          }
        ]
      }
      
      network_performance = {
        title = "Network Performance"
        folder = "HPC"
        panels = [
          {
            title = "EFA Performance"
            type = "graph"
            targets = [
              {
                expr = "histogram_quantile(0.95, efa_latency_histogram)"
                legendFormat = "95th percentile latency"
              },
              {
                expr = "histogram_quantile(0.99, efa_latency_histogram)"
                legendFormat = "99th percentile latency"
              }
            ]
          },
          {
            title = "Network Congestion"
            type = "graph"
            targets = [
              {
                expr = "rate(network_retransmits_total[5m])"
                legendFormat = "Retransmits/sec"
              },
              {
                expr = "rate(network_drops_total[5m])"
                legendFormat = "Drops/sec"
              }
            ]
          }
        ]
      }
    }
  }
  
  # Prometheus Configuration
  prometheus_config = {
    # Scrape configurations for HPC metrics
    scrape_configs = [
      {
        job_name = "slurm-exporter"
        static_configs = [
          {
            targets = ["slurm-exporter:8080"]
          }
        ]
        scrape_interval = "30s"
        metrics_path = "/metrics"
      },
      {
        job_name = "node-exporter"
        static_configs = [
          {
            targets = ["node-exporter:9100"]
          }
        ]
        scrape_interval = "15s"
        metrics_path = "/metrics"
      },
      {
        job_name = "fsx-exporter"
        static_configs = [
          {
            targets = ["fsx-exporter:8080"]
          }
        ]
        scrape_interval = "30s"
        metrics_path = "/metrics"
      }
    ]
    
    # Recording rules for HPC metrics
    recording_rules = [
      {
        name = "hpc_job_efficiency"
        rules = [
          {
            record = "hpc:job_efficiency_5m"
            expr = "avg_over_time(slurm_job_cpu_efficiency[5m])"
          },
          {
            record = "hpc:job_efficiency_1h"
            expr = "avg_over_time(slurm_job_cpu_efficiency[1h])"
          }
        ]
      },
      {
        name = "hpc_network_performance"
        rules = [
          {
            record = "hpc:mpi_latency_95p"
            expr = "histogram_quantile(0.95, mpi_latency_histogram)"
          },
          {
            record = "hpc:mpi_latency_99p"
            expr = "histogram_quantile(0.99, mpi_latency_histogram)"
          }
        ]
      }
    ]
  }
  
  # VPC Flow Logs Configuration
  vpc_flow_logs = {
    log_destination_type = "s3"
    log_destination = "arn:aws:s3:::${local.s3_config.flow_logs.bucket_name}/vpc-flow-logs/"
    traffic_type = "ALL"
    log_format = "$version $account-id $interface-id $srcaddr $dstaddr $srcport $dstport $protocol $packets $bytes $windowstart $windowend $action $tcp-flags $flow-log-status"
    
    # Custom fields for HPC analysis
    custom_fields = [
      "srcaddr",
      "dstaddr",
      "srcport",
      "dstport",
      "protocol",
      "packets",
      "bytes",
      "action"
    ]
  }
  
  # X-Ray Configuration for distributed tracing
  xray_config = {
    sampling_rule = {
      rule_name = "hpc-sampling-rule"
      priority = 1000
      version = 1
      reservoir_size = 1000
      fixed_rate = 0.1  # 10% sampling
      url_path = "*"
      host = "*"
      http_method = "*"
      service_type = "*"
      service_name = "*"
      resource_arn = "*"
      attributes = {
        "Environment" = local.environment
        "Service" = "HPC"
      }
    }
  }
  
  # Cost and Budget Monitoring
  budget_config = {
    budget_name = "hpc-monthly-budget-${local.environment}"
    budget_type = "COST"
    limit_amount = "200000"  # $200,000
    limit_unit = "USD"
    time_unit = "MONTHLY"
    time_period_start = "2024-01-01_00:00"
    
    # Budget alerts
    notifications = [
      {
        comparison_operator = "GREATER_THAN"
        threshold = 50  # 50% of budget
        threshold_type = "PERCENTAGE"
        notification_type = "ACTUAL"
        subscriber_email_addresses = ["hpc-team@example.com"]
      },
      {
        comparison_operator = "GREATER_THAN"
        threshold = 80  # 80% of budget
        threshold_type = "PERCENTAGE"
        notification_type = "ACTUAL"
        subscriber_email_addresses = ["hpc-team@example.com", "finance@example.com"]
      },
      {
        comparison_operator = "GREATER_THAN"
        threshold = 100  # 100% of budget
        threshold_type = "PERCENTAGE"
        notification_type = "ACTUAL"
        subscriber_email_addresses = ["hpc-team@example.com", "finance@example.com", "management@example.com"]
      }
    ]
    
    # Cost allocation tags
    cost_filters = {
      TagKey = ["Environment", "Project", "CostCenter"]
    }
  }
}
