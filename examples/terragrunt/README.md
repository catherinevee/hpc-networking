# Terragrunt Example for HPC Networking Module

This example demonstrates how to use the HPC Networking Terraform module with Terragrunt for improved state management, dependency handling, and configuration management.

## Prerequisites

- Terragrunt >= 0.54.0
- Terraform >= 1.12.2
- AWS CLI configured
- S3 bucket for remote state storage
- DynamoDB table for state locking

## Setup

### 1. Create S3 Bucket and DynamoDB Table

```bash
# Create S3 bucket for Terraform state
aws s3 mb s3://hpc-networking-terraform-state

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket hpc-networking-terraform-state \
  --versioning-configuration Status=Enabled

# Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name hpc-networking-terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
  --region us-east-1
```

### 2. Configure Your VPC ID

Edit `terragrunt.hcl` and replace `vpc-12345678` with your actual VPC ID:

```hcl
inputs = {
  vpc_id = "vpc-your-actual-vpc-id"
  # ... other inputs
}
```

### 3. Deploy with Terragrunt

```bash
# Initialize Terragrunt
terragrunt init

# Plan the deployment
terragrunt plan

# Apply the configuration
terragrunt apply

# To destroy the infrastructure
terragrunt destroy
```

## Configuration Details

### Root Configuration (`root.hcl`)

The root configuration provides:
- Remote state management with S3 backend
- State locking with DynamoDB
- Global provider configuration
- Common tags and settings

### Module Configuration (`terragrunt.hcl`)

The module configuration includes:
- Auto-scaling HPC cluster (2-16 instances)
- P5.48xlarge instances with EFA
- FSx for Lustre storage (14.4TB)
- Advanced networking features
- Complete monitoring setup

## Key Features Demonstrated

### Remote State Management
- State stored in S3 with encryption
- State locking with DynamoDB
- Automatic backend configuration

### Provider Management
- Pinned provider versions for consistency
- Default tags for all resources
- Centralized provider configuration

### Configuration Management
- Environment-specific configurations
- Common settings in root configuration
- Override capabilities for specific needs

### Auto Scaling
- Minimum 2, maximum 16 instances
- Target tracking scaling policies
- Health checks and grace periods

### Advanced Networking
- EFA with GPUDirect support
- Jumbo frames (9001 MTU)
- SR-IOV and NUMA optimization
- Cluster placement strategy

### Storage
- FSx for Lustre with S3 data repository
- 14.4TB storage capacity
- GPUDirect Storage support

### Monitoring
- CloudWatch metrics and alarms
- 90-day log retention
- Performance monitoring

## Usage Examples

### Deploy with Custom Configuration

```bash
# Deploy with specific instance count
terragrunt apply -var="instance_count=4"

# Deploy with spot instances
terragrunt apply -var="allow_spot_instances=true"

# Deploy with custom storage capacity
terragrunt apply -var="fsx_storage_capacity=28800"
```

### Multi-Environment Deployment

```bash
# Deploy to development environment
cd environments/dev
terragrunt apply

# Deploy to production environment
cd environments/prod
terragrunt apply
```

### Outputs

After deployment, you can view outputs:

```bash
# View all outputs
terragrunt output

# View specific output
terragrunt output instance_ips
terragrunt output fsx_mount_command
terragrunt output performance_metrics
```

## Troubleshooting

### Common Issues

1. **State Lock Issues**
   ```bash
   # Force unlock if needed (use with caution)
   terragrunt force-unlock <lock-id>
   ```

2. **Provider Version Conflicts**
   ```bash
   # Clean and reinitialize
   terragrunt clean
   terragrunt init
   ```

3. **S3 Backend Issues**
   ```bash
   # Verify S3 bucket exists and is accessible
   aws s3 ls s3://hpc-networking-terraform-state
   ```

### Debug Commands

```bash
# Show Terragrunt configuration
terragrunt show

# Validate configuration
terragrunt validate

# Show execution plan
terragrunt plan -detailed-exitcode
```

## Best Practices

1. **State Management**
   - Always use remote state with S3
   - Enable state locking with DynamoDB
   - Use separate state files for different environments

2. **Version Pinning**
   - Pin Terraform version to 1.12.2
   - Pin provider versions for consistency
   - Use version constraints in root configuration

3. **Security**
   - Enable encryption for S3 state storage
   - Use IAM roles with least privilege
   - Enable CloudTrail for audit logging

4. **Monitoring**
   - Enable CloudWatch monitoring
   - Set up alerts for critical metrics
   - Use proper log retention policies

## Cost Optimization

- VPC endpoints reduce NAT gateway costs
- Spot instances for non-production workloads
- Auto scaling based on actual demand
- Proper resource tagging for cost allocation

## Support

For issues with this Terragrunt example:
- Check the main module documentation
- Review Terragrunt logs for errors
- Verify AWS permissions and configuration
- Ensure all prerequisites are met 