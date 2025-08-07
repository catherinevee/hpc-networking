# High-Performance Networking Module - Security Resources
# Security groups, IAM roles, and policies for EFA-enabled workloads

# Security Group for EFA-enabled instances
resource "aws_security_group" "efa" {
  name_prefix = "${var.project_name}-efa-"
  description = "Security group for EFA-enabled instances"
  vpc_id      = var.vpc_id

  # All traffic within security group for EFA
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
    description = "All traffic within EFA security group"
  }

  # SSH access from allowed CIDR blocks
  dynamic "ingress" {
    for_each = var.allowed_cidr_blocks
    content {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
      description = "SSH access from ${ingress.value}"
    }
  }

  # EFA-specific ports
  ingress {
    from_port   = 18515
    to_port     = 18515
    protocol    = "tcp"
    self        = true
    description = "EFA communication port"
  }

  ingress {
    from_port   = 18516
    to_port     = 18516
    protocol    = "tcp"
    self        = true
    description = "EFA communication port"
  }

  # NCCL ports for distributed training
  ingress {
    from_port   = 29500
    to_port     = 29599
    protocol    = "tcp"
    self        = true
    description = "NCCL communication ports"
  }

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-efa-sg"
    Purpose = "EFA-Communication"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Security Group for FSx for Lustre
resource "aws_security_group" "fsx" {
  count = var.enable_fsx_lustre ? 1 : 0

  name_prefix = "${var.project_name}-fsx-"
  description = "Security group for FSx for Lustre"
  vpc_id      = var.vpc_id

  # Lustre ports
  ingress {
    from_port       = 988
    to_port         = 988
    protocol        = "tcp"
    security_groups = [aws_security_group.efa.id]
    description     = "Lustre management port"
  }

  ingress {
    from_port       = 1021
    to_port         = 1023
    protocol        = "tcp"
    security_groups = [aws_security_group.efa.id]
    description     = "Lustre data ports"
  }

  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.efa.id]
    description     = "NFS port"
  }

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-fsx-sg"
    Purpose = "Lustre-Storage"
  })
}

# Security Group for VPC Endpoints
resource "aws_security_group" "vpc_endpoints" {
  count = var.enable_vpc_endpoints ? 1 : 0

  name_prefix = "${var.project_name}-endpoints-"
  description = "Security group for VPC endpoints"
  vpc_id      = var.vpc_id

  # HTTPS access from compute instances
  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.efa.id]
    description     = "HTTPS access from compute instances"
  }

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-endpoints-sg"
    Purpose = "VPC-Endpoints"
  })
}

# IAM Role for EC2 instances
resource "aws_iam_role" "ec2_role" {
  name = "${var.project_name}-ec2-role"

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
    Name = "${var.project_name}-ec2-role"
  })
}

# IAM Policy for EC2 instances
resource "aws_iam_role_policy" "ec2_policy" {
  name = "${var.project_name}-ec2-policy"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeTags",
          "ec2:DescribeVolumes",
          "ec2:DescribeNetworkInterfaces"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.project_name}-*",
          "arn:aws:s3:::${var.project_name}-*/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/hpc-networking/*"
      },
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
          "cloudwatch:GetMetricData",
          "cloudwatch:ListMetrics"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = "*"
      }
    ]
  })
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-ec2-profile"
  role = aws_iam_role.ec2_role.name

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-ec2-profile"
  })
}

# IAM Role for CloudWatch monitoring
resource "aws_iam_role" "cloudwatch_role" {
  count = var.enable_cloudwatch ? 1 : 0

  name = "${var.project_name}-cloudwatch-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-cloudwatch-role"
  })
}

# IAM Policy for CloudWatch monitoring
resource "aws_iam_role_policy" "cloudwatch_policy" {
  count = var.enable_cloudwatch ? 1 : 0

  name = "${var.project_name}-cloudwatch-policy"
  role = aws_iam_role.cloudwatch_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
          "cloudwatch:GetMetricData",
          "cloudwatch:ListMetrics",
          "cloudwatch:DescribeAlarms",
          "cloudwatch:PutMetricAlarm",
          "cloudwatch:DeleteAlarms"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/hpc-networking/*"
      }
    ]
  })
}

# KMS Key for encryption (if enabled)
resource "aws_kms_key" "hpc_encryption" {
  count = var.enable_encryption ? 1 : 0

  description             = "KMS key for HPC networking encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow CloudWatch Logs"
        Effect = "Allow"
        Principal = {
          Service = "logs.${data.aws_region.current.name}.amazonaws.com"
        }
        Action = [
          "kms:Encrypt*",
          "kms:Decrypt*",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:Describe*"
        ]
        Resource = "*"
        Condition = {
          ArnEquals = {
            "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/hpc-networking/*"
          }
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-encryption-key"
  })
}

# KMS Key Alias
resource "aws_kms_alias" "hpc_encryption" {
  count = var.enable_encryption ? 1 : 0

  name          = "alias/${var.project_name}-encryption"
  target_key_id = aws_kms_key.hpc_encryption[0].key_id
}

# Security Group for Load Balancer (if needed)
resource "aws_security_group" "alb" {
  count = var.enable_auto_scaling ? 1 : 0

  name_prefix = "${var.project_name}-alb-"
  description = "Security group for Application Load Balancer"
  vpc_id      = var.vpc_id

  # HTTP access
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
    description = "HTTP access"
  }

  # HTTPS access
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
    description = "HTTPS access"
  }

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-alb-sg"
    Purpose = "Load-Balancer"
  })
}

# Network ACL for additional security
resource "aws_network_acl" "storage" {
  count = var.enable_fsx_lustre ? 1 : 0

  vpc_id = var.vpc_id

  # Lustre ports
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = var.vpc_cidr
    from_port  = 988
    to_port    = 988
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = var.vpc_cidr
    from_port  = 1021
    to_port    = 1023
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 120
    action     = "allow"
    cidr_block = var.vpc_cidr
    from_port  = 2049
    to_port    = 2049
  }

  # All outbound traffic
  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-storage-nacl"
  })
}

resource "aws_network_acl_association" "storage" {
  count = var.enable_fsx_lustre ? length(local.private_storage_subnets) : 0

  network_acl_id = aws_network_acl.storage[0].id
  subnet_id      = aws_subnet.private_storage[count.index].id
} 