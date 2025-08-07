# High-Performance Networking Module - Networking Resources
# Subnets, route tables, VPC endpoints, and network optimization

# Public Subnets for NAT Gateways and Load Balancers
resource "aws_subnet" "public" {
  count = length(local.public_subnets)

  vpc_id                  = var.vpc_id
  cidr_block              = local.public_subnets[count.index].cidr_block
  availability_zone       = local.public_subnets[count.index].az
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-public-${local.public_subnets[count.index].az}"
    Tier = "Public"
    Purpose = "NAT-ALB"
  })
}

# Private Compute Subnets for Training Nodes
resource "aws_subnet" "private_compute" {
  count = length(local.private_compute_subnets)

  vpc_id            = var.vpc_id
  cidr_block        = local.private_compute_subnets[count.index].cidr_block
  availability_zone = local.private_compute_subnets[count.index].az

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-compute-${local.private_compute_subnets[count.index].az}"
    Tier = "Private"
    Purpose = "Compute"
    NetworkOptimized = "true"
    EFAEnabled = var.enable_efa
  })
}

# Private Storage Subnets for FSx for Lustre
resource "aws_subnet" "private_storage" {
  count = length(local.private_storage_subnets)

  vpc_id            = var.vpc_id
  cidr_block        = local.private_storage_subnets[count.index].cidr_block
  availability_zone = local.private_storage_subnets[count.index].az

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-storage-${local.private_storage_subnets[count.index].az}"
    Tier = "Private"
    Purpose = "Storage"
    StorageType = "HighPerformance"
  })
}

# Private Endpoint Subnets for VPC Endpoints
resource "aws_subnet" "private_endpoint" {
  count = length(local.private_endpoint_subnets)

  vpc_id            = var.vpc_id
  cidr_block        = local.private_endpoint_subnets[count.index].cidr_block
  availability_zone = local.private_endpoint_subnets[count.index].az

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-endpoint-${local.private_endpoint_subnets[count.index].az}"
    Tier = "Private"
    Purpose = "Endpoints"
  })
}

# Internet Gateway (if not exists)
resource "aws_internet_gateway" "main" {
  count = length(data.aws_internet_gateway.vpc.ids) == 0 ? 1 : 0

  vpc_id = var.vpc_id

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-igw"
  })
}

# NAT Gateways for private subnets
resource "aws_eip" "nat" {
  count = length(local.public_subnets)

  domain = "vpc"

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-nat-eip-${count.index + 1}"
  })
}

resource "aws_nat_gateway" "main" {
  count = length(local.public_subnets)

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-nat-${count.index + 1}"
  })

  depends_on = [aws_internet_gateway.main]
}

# Route Tables
resource "aws_route_table" "public" {
  vpc_id = var.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = length(data.aws_internet_gateway.vpc.ids) > 0 ? data.aws_internet_gateway.vpc.ids[0] : aws_internet_gateway.main[0].id
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-public-rt"
  })
}

resource "aws_route_table" "private_compute" {
  count = length(local.private_compute_subnets)

  vpc_id = var.vpc_id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index % length(aws_nat_gateway.main)].id
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-compute-rt-${count.index + 1}"
  })
}

resource "aws_route_table" "private_storage" {
  count = length(local.private_storage_subnets)

  vpc_id = var.vpc_id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index % length(aws_nat_gateway.main)].id
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-storage-rt-${count.index + 1}"
  })
}

resource "aws_route_table" "private_endpoint" {
  count = length(local.private_endpoint_subnets)

  vpc_id = var.vpc_id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index % length(aws_nat_gateway.main)].id
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-endpoint-rt-${count.index + 1}"
  })
}

# Route Table Associations
resource "aws_route_table_association" "public" {
  count = length(local.public_subnets)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_compute" {
  count = length(local.private_compute_subnets)

  subnet_id      = aws_subnet.private_compute[count.index].id
  route_table_id = aws_route_table.private_compute[count.index].id
}

resource "aws_route_table_association" "private_storage" {
  count = length(local.private_storage_subnets)

  subnet_id      = aws_subnet.private_storage[count.index].id
  route_table_id = aws_route_table.private_storage[count.index].id
}

resource "aws_route_table_association" "private_endpoint" {
  count = length(local.private_endpoint_subnets)

  subnet_id      = aws_subnet.private_endpoint[count.index].id
  route_table_id = aws_route_table.private_endpoint[count.index].id
}

# VPC Endpoints for cost optimization
resource "aws_vpc_endpoint" "s3" {
  count = var.enable_vpc_endpoints ? 1 : 0

  vpc_id       = var.vpc_id
  service_name = "com.amazonaws.${data.aws_region.current.name}.s3"

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-s3-endpoint"
  })
}

resource "aws_vpc_endpoint" "dynamodb" {
  count = var.enable_vpc_endpoints ? 1 : 0

  vpc_id       = var.vpc_id
  service_name = "com.amazonaws.${data.aws_region.current.name}.dynamodb"

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-dynamodb-endpoint"
  })
}

resource "aws_vpc_endpoint" "sagemaker_api" {
  count = var.enable_vpc_endpoints ? 1 : 0

  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.sagemaker.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private_endpoint[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-sagemaker-api-endpoint"
  })
}

resource "aws_vpc_endpoint" "sagemaker_runtime" {
  count = var.enable_vpc_endpoints ? 1 : 0

  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.sagemaker.runtime"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private_endpoint[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-sagemaker-runtime-endpoint"
  })
}

resource "aws_vpc_endpoint" "fsx" {
  count = var.enable_vpc_endpoints ? 1 : 0

  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.fsx"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private_endpoint[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-fsx-endpoint"
  })
}

resource "aws_vpc_endpoint" "efs" {
  count = var.enable_vpc_endpoints ? 1 : 0

  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.elasticfilesystem"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private_endpoint[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-efs-endpoint"
  })
}

resource "aws_vpc_endpoint" "ec2" {
  count = var.enable_vpc_endpoints ? 1 : 0

  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ec2"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private_endpoint[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-ec2-endpoint"
  })
}

resource "aws_vpc_endpoint" "ecr_api" {
  count = var.enable_vpc_endpoints ? 1 : 0

  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private_endpoint[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-ecr-api-endpoint"
  })
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  count = var.enable_vpc_endpoints ? 1 : 0

  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private_endpoint[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-ecr-dkr-endpoint"
  })
}

resource "aws_vpc_endpoint" "logs" {
  count = var.enable_vpc_endpoints ? 1 : 0

  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private_endpoint[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-logs-endpoint"
  })
}

resource "aws_vpc_endpoint" "monitoring" {
  count = var.enable_vpc_endpoints ? 1 : 0

  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.monitoring"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private_endpoint[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-monitoring-endpoint"
  })
}

# VPC Endpoint Route Table Associations
resource "aws_vpc_endpoint_route_table_association" "s3" {
  count = var.enable_vpc_endpoints ? length(local.private_compute_subnets) : 0

  route_table_id  = aws_route_table.private_compute[count.index].id
  vpc_endpoint_id = aws_vpc_endpoint.s3[0].id
}

resource "aws_vpc_endpoint_route_table_association" "dynamodb" {
  count = var.enable_vpc_endpoints ? length(local.private_compute_subnets) : 0

  route_table_id  = aws_route_table.private_compute[count.index].id
  vpc_endpoint_id = aws_vpc_endpoint.dynamodb[0].id
}

# Network ACLs for additional security
resource "aws_network_acl" "compute" {
  vpc_id = var.vpc_id

  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  ingress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-compute-nacl"
  })
}

resource "aws_network_acl_association" "compute" {
  count = length(local.private_compute_subnets)

  network_acl_id = aws_network_acl.compute.id
  subnet_id      = aws_subnet.private_compute[count.index].id
}

# Network Performance Optimization
resource "null_resource" "network_optimization" {
  count = var.enable_jumbo_frames ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
      echo "Network optimization settings:"
      echo "- MTU Size: ${local.mtu_size}"
      echo "- Jumbo Frames: ${var.enable_jumbo_frames}"
      echo "- SR-IOV: ${var.enable_sriov}"
      echo "- NUMA Optimization: ${var.numa_optimization}"
    EOT
  }

  triggers = {
    mtu_size = local.mtu_size
    enable_jumbo_frames = var.enable_jumbo_frames
    enable_sriov = var.enable_sriov
    numa_optimization = var.numa_optimization
  }
} 