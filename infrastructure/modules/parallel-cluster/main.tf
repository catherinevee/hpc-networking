# ParallelCluster Module for HPC Infrastructure
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
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

# Placeholder resource for ParallelCluster
# In a real implementation, this would be replaced with actual ParallelCluster resources
resource "aws_instance" "placeholder" {
  count = var.create_cluster ? 1 : 0

  ami           = data.aws_ami.hpc_optimized.id
  instance_type = var.head_node_instance_type

  subnet_id = var.subnet_id
  vpc_security_group_ids = var.security_group_ids

  tags = merge(var.common_tags, var.tags, {
    Name = "${var.cluster_name}-placeholder"
    Type = "ParallelCluster-Placeholder"
  })
}
