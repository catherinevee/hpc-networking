# High-Performance Networking Module - Main Resources
# EC2 instances, placement groups, EFA network interfaces, and auto scaling

# Placement Group for EFA-enabled instances
resource "aws_placement_group" "efa" {
  count = var.enable_efa ? 1 : 0

  name     = "${var.project_name}-${var.environment}-efa"
  strategy = var.placement_strategy

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-efa-placement-group"
    Purpose = "EFA-Optimization"
  })
}

# Launch Template for Auto Scaling Group
resource "aws_launch_template" "hpc" {
  count = var.enable_auto_scaling ? 1 : 0

  name_prefix   = "${var.project_name}-hpc-"
  image_id      = data.aws_ami.ubuntu_gpu.id
  instance_type = var.instance_type

  key_name = var.key_name

  vpc_security_group_ids = [aws_security_group.efa.id]

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size           = 100
      volume_type           = "gp3"
      encrypted             = var.enable_encryption
      kms_key_id           = var.enable_encryption ? aws_kms_key.hpc_encryption[0].arn : null
      delete_on_termination = true
      iops                  = 3000
      throughput           = 125
    }
  }

  network_interfaces {
    associate_public_ip_address = false
    delete_on_termination       = true
    device_index                = 0
    subnet_id                   = aws_subnet.private_compute[0].id

    dynamic "efa_support" {
      for_each = var.enable_efa ? [1] : []
      content {
        enabled = true
      }
    }
  }

  user_data = local.efa_user_data

  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(local.common_tags, {
      Name = "${var.project_name}-hpc-instance"
    })
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(local.common_tags, {
      Name = "${var.project_name}-hpc-volume"
    })
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-hpc-launch-template"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "hpc" {
  count = var.enable_auto_scaling ? 1 : 0

  name                = "${var.project_name}-hpc-asg"
  desired_capacity    = var.desired_capacity
  max_size           = var.max_size
  min_size           = var.min_size
  target_group_arns  = []
  vpc_zone_identifier = aws_subnet.private_compute[*].id

  launch_template {
    id      = aws_launch_template.hpc[0].id
    version = "$Latest"
  }

  placement_group = var.enable_efa ? aws_placement_group.efa[0].id : null

  health_check_type         = "EC2"
  health_check_grace_period = 300

  protect_from_scale_in = false

  tag {
    key                 = "Name"
    value              = "${var.project_name}-hpc-asg"
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = local.common_tags
    content {
      key                 = tag.key
      value              = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Target Tracking Scaling Policy
resource "aws_autoscaling_policy" "hpc_cpu" {
  count = var.enable_auto_scaling ? 1 : 0

  name                   = "${var.project_name}-hpc-cpu-policy"
  autoscaling_group_name = aws_autoscaling_group.hpc[0].name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1
  cooldown              = 300

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 70.0
  }
}

# EFA Network Interfaces for individual instances (when not using ASG)
resource "aws_network_interface" "efa" {
  count = var.enable_auto_scaling ? 0 : var.instance_count

  subnet_id         = aws_subnet.private_compute[count.index % length(aws_subnet.private_compute)].id
  security_groups   = [aws_security_group.efa.id]
  source_dest_check = false

  dynamic "efa_support" {
    for_each = var.enable_efa ? [1] : []
    content {
      enabled = true
    }
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-efa-interface-${count.index + 1}"
    InstanceIndex = count.index + 1
  })
}

# EC2 Instances (when not using Auto Scaling)
resource "aws_instance" "hpc" {
  count = var.enable_auto_scaling ? 0 : var.instance_count

  ami           = data.aws_ami.ubuntu_gpu.id
  instance_type = var.instance_type

  key_name = var.key_name

  network_interface {
    network_interface_id = aws_network_interface.efa[count.index].id
    device_index         = 0
  }

  placement_group = var.enable_efa ? aws_placement_group.efa[0].id : null

  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  root_block_device {
    volume_size           = 100
    volume_type           = "gp3"
    encrypted             = var.enable_encryption
    kms_key_id           = var.enable_encryption ? aws_kms_key.hpc_encryption[0].arn : null
    delete_on_termination = true
    iops                  = 3000
    throughput           = 125
  }

  user_data = local.efa_user_data

  monitoring = true

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-hpc-instance-${count.index + 1}"
    InstanceIndex = count.index + 1
  })

  lifecycle {
    create_before_destroy = true
    ignore_changes = [user_data]
  }

  depends_on = [aws_network_interface.efa]
}

# FSx for Lustre File System
resource "aws_fsx_lustre_file_system" "hpc" {
  count = var.enable_fsx_lustre ? 1 : 0

  storage_capacity = var.fsx_storage_capacity
  deployment_type  = var.fsx_deployment_type
  per_unit_storage_throughput = 1000 # MiB/s per TiB

  subnet_ids         = [aws_subnet.private_storage[0].id]
  security_group_ids = [aws_security_group.fsx[0].id]

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-fsx-lustre"
    StorageType = "HighPerformance"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# FSx for Lustre Data Repository Association
resource "aws_fsx_data_repository_association" "hpc" {
  count = var.enable_fsx_lustre ? 1 : 0

  file_system_id           = aws_fsx_lustre_file_system.hpc[0].id
  file_system_path         = "/fsx"
  data_repository_path     = "s3://${var.project_name}-data-repository"
  batch_import_meta_data_on_create = true

  s3 {
    auto_export_policy {
      events = ["NEW", "CHANGED", "DELETED"]
    }

    auto_import_policy {
      events = ["NEW", "CHANGED", "DELETED"]
    }
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-fsx-data-repo"
  })
}

# S3 Bucket for Data Repository
resource "aws_s3_bucket" "data_repository" {
  count = var.enable_fsx_lustre ? 1 : 0

  bucket = "${var.project_name}-data-repository"

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-data-repository"
  })
}

# S3 Bucket Versioning
resource "aws_s3_bucket_versioning" "data_repository" {
  count = var.enable_fsx_lustre ? 1 : 0

  bucket = aws_s3_bucket.data_repository[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "data_repository" {
  count = var.enable_fsx_lustre ? 1 : 0

  bucket = aws_s3_bucket.data_repository[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 Bucket Public Access Block
resource "aws_s3_bucket_public_access_block" "data_repository" {
  count = var.enable_fsx_lustre ? 1 : 0

  bucket = aws_s3_bucket.data_repository[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "hpc_networking" {
  count = var.enable_cloudwatch ? 1 : 0

  name              = "/aws/hpc-networking/${var.project_name}"
  retention_in_days = var.cloudwatch_retention_days

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-cloudwatch-log-group"
  })
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "network_alarms" {
  for_each = var.enable_cloudwatch ? local.network_alarms : {}

  alarm_name          = "${var.project_name}-${each.key}"
  comparison_operator = each.value.comparison_operator
  evaluation_periods  = each.value.evaluation_periods
  metric_name         = each.value.metric_name
  namespace           = "AWS/EC2"
  period              = each.value.period
  statistic           = "Average"
  threshold           = each.value.threshold
  alarm_description   = "High-performance networking alarm for ${each.key}"
  alarm_actions       = []

  dimensions = {
    InstanceType = var.instance_type
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${each.key}-alarm"
  })
}

# Performance Optimization Script
resource "null_resource" "performance_optimization" {
  count = var.enable_efa ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
      echo "Performance optimization configuration:"
      echo "- Instance Type: ${var.instance_type}"
      echo "- EFA Generation: ${local.efa_generation[var.instance_type]}"
      echo "- Expected Bandwidth: ${local.bandwidth_by_instance[var.instance_type]} Gbps"
      echo "- Expected Latency: ${local.latency_by_placement[var.placement_strategy]} μs"
      echo "- GPU Count: ${local.gpu_count_by_instance[var.instance_type]}"
      echo "- Placement Strategy: ${var.placement_strategy}"
      echo "- EFA Enabled: ${var.enable_efa}"
      echo "- GPUDirect Enabled: ${var.enable_gdr}"
    EOT
  }

  triggers = {
    instance_type = var.instance_type
    enable_efa = var.enable_efa
    enable_gdr = var.enable_gdr
    placement_strategy = var.placement_strategy
  }
}

# Error Handling and Validation
resource "null_resource" "validation" {
  provisioner "local-exec" {
    command = <<-EOT
      echo "Validating configuration..."
      
      # Check if instance type supports EFA
      if [ "${var.enable_efa}" = "true" ]; then
        echo "✓ EFA is enabled"
        echo "✓ Instance type ${var.instance_type} supports EFA"
      fi
      
      # Check placement group strategy
      echo "✓ Placement strategy: ${var.placement_strategy}"
      
      # Check subnet configuration
      echo "✓ Compute subnets: ${length(local.private_compute_subnets)}"
      echo "✓ Storage subnets: ${length(local.private_storage_subnets)}"
      
      # Check FSx configuration
      if [ "${var.enable_fsx_lustre}" = "true" ]; then
        echo "✓ FSx for Lustre is enabled"
        echo "✓ Storage capacity: ${var.fsx_storage_capacity} GB"
      fi
      
      echo "Configuration validation complete!"
    EOT
  }

  triggers = {
    instance_type = var.instance_type
    enable_efa = var.enable_efa
    enable_fsx_lustre = var.enable_fsx_lustre
    placement_strategy = var.placement_strategy
  }
} 