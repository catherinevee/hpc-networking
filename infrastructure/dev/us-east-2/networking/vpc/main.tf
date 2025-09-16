# Security Group for VPC Endpoints
resource "aws_security_group" "vpc_endpoints" {
  name_prefix = "hpc-${var.environment}-vpc-endpoints-"
  vpc_id      = module.vpc.vpc_id
  description = "Security group for VPC endpoints"
  
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "HTTPS from VPC"
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }
  
  tags = merge(var.common_tags, {
    Name = "hpc-${var.environment}-vpc-endpoints-sg"
    Type = "VPC-Endpoints-SecurityGroup"
  })
  
  lifecycle {
    create_before_destroy = true
  }
}

# VPC Endpoints for AWS services
resource "aws_vpc_endpoint" "ec2" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.region}.ec2"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true
  
  tags = merge(var.common_tags, {
    Name = "hpc-${var.environment}-ec2-endpoint"
    Type = "VPC-Endpoint"
  })
}

resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.region}.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true
  
  tags = merge(var.common_tags, {
    Name = "hpc-${var.environment}-ec2messages-endpoint"
    Type = "VPC-Endpoint"
  })
}

resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.region}.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true
  
  tags = merge(var.common_tags, {
    Name = "hpc-${var.environment}-ssm-endpoint"
    Type = "VPC-Endpoint"
  })
}

resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true
  
  tags = merge(var.common_tags, {
    Name = "hpc-${var.environment}-ssmmessages-endpoint"
    Type = "VPC-Endpoint"
  })
}

resource "aws_vpc_endpoint" "cloudwatch" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.region}.monitoring"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true
  
  tags = merge(var.common_tags, {
    Name = "hpc-${var.environment}-cloudwatch-endpoint"
    Type = "VPC-Endpoint"
  })
}

resource "aws_vpc_endpoint" "cloudwatchlogs" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.region}.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true
  
  tags = merge(var.common_tags, {
    Name = "hpc-${var.environment}-cloudwatchlogs-endpoint"
    Type = "VPC-Endpoint"
  })
}
