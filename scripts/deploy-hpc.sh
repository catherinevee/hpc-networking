#!/bin/bash
# HPC Infrastructure Deployment Script

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
ENVIRONMENT="dev"
REGION="us-east-2"
ACTION="plan"
CLUSTER_SIZE="50"
VERBOSE=false

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to show usage
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Deploy HPC infrastructure using Terragrunt and AWS ParallelCluster.

OPTIONS:
    -e, --environment ENV     Target environment (dev, staging, production) [default: dev]
    -r, --region REGION       AWS region [default: us-east-2]
    -a, --action ACTION       Action to perform (plan, apply, destroy, scale-up, scale-down) [default: plan]
    -s, --cluster-size SIZE   Target cluster size for scaling actions [default: 50]
    -v, --verbose             Enable verbose output
    -h, --help                Show this help message

EXAMPLES:
    # Plan deployment for dev environment
    $0 --environment dev --action plan

    # Deploy dev environment
    $0 --environment dev --action apply

    # Scale up cluster to 100 nodes
    $0 --environment dev --action scale-up --cluster-size 100

    # Destroy staging environment
    $0 --environment staging --action destroy

EOF
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if AWS CLI is installed
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install it first."
        exit 1
    fi
    
    # Check if Terraform is installed
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed. Please install it first."
        exit 1
    fi
    
    # Check if Terragrunt is installed
    if ! command -v terragrunt &> /dev/null; then
        print_error "Terragrunt is not installed. Please install it first."
        exit 1
    fi
    
    # Check if AWS ParallelCluster is installed
    if ! command -v pcluster &> /dev/null; then
        print_error "AWS ParallelCluster is not installed. Please install it first."
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials are not configured. Please run 'aws configure' first."
        exit 1
    fi
    
    print_success "All prerequisites are met"
}

# Function to validate environment
validate_environment() {
    print_status "Validating environment configuration..."
    
    local env_dir="infrastructure/${ENVIRONMENT}"
    if [ ! -d "$env_dir" ]; then
        print_error "Environment directory $env_dir does not exist"
        exit 1
    fi
    
    local region_dir="${env_dir}/${REGION}"
    if [ ! -d "$region_dir" ]; then
        print_error "Region directory $region_dir does not exist"
        exit 1
    fi
    
    print_success "Environment configuration is valid"
}

# Function to deploy infrastructure
deploy_infrastructure() {
    print_status "Deploying infrastructure for ${ENVIRONMENT} environment in ${REGION}..."
    
    local infra_dir="infrastructure/${ENVIRONMENT}/${REGION}"
    
    # Deploy networking
    print_status "Deploying networking components..."
    cd "${infra_dir}/networking"
    if [ "$VERBOSE" = true ]; then
        terragrunt run-all ${ACTION} --terragrunt-log-level debug
    else
        terragrunt run-all ${ACTION}
    fi
    
    if [ "$ACTION" = "apply" ]; then
        print_success "Networking components deployed successfully"
    fi
    
    # Deploy storage
    print_status "Deploying storage components..."
    cd "../storage"
    if [ "$VERBOSE" = true ]; then
        terragrunt run-all ${ACTION} --terragrunt-log-level debug
    else
        terragrunt run-all ${ACTION}
    fi
    
    if [ "$ACTION" = "apply" ]; then
        print_success "Storage components deployed successfully"
    fi
    
    # Deploy compute
    print_status "Deploying compute components..."
    cd "../compute"
    if [ "$VERBOSE" = true ]; then
        terragrunt run-all ${ACTION} --terragrunt-log-level debug
    else
        terragrunt run-all ${ACTION}
    fi
    
    if [ "$ACTION" = "apply" ]; then
        print_success "Compute components deployed successfully"
    fi
    
    # Deploy monitoring
    print_status "Deploying monitoring components..."
    cd "../monitoring"
    if [ "$VERBOSE" = true ]; then
        terragrunt run-all ${ACTION} --terragrunt-log-level debug
    else
        terragrunt run-all ${ACTION}
    fi
    
    if [ "$ACTION" = "apply" ]; then
        print_success "Monitoring components deployed successfully"
    fi
    
    cd - > /dev/null
}

# Function to deploy cluster
deploy_cluster() {
    if [ "$ACTION" = "destroy" ]; then
        print_status "Destroying cluster..."
        pcluster delete-cluster --cluster-name "hpc-${ENVIRONMENT}" --region "$REGION" --yes
        print_success "Cluster destroyed successfully"
    else
        print_status "Deploying cluster..."
        pcluster create-cluster \
            --cluster-name "hpc-${ENVIRONMENT}" \
            --cluster-configuration "cluster-configs/${ENVIRONMENT}.yaml" \
            --region "$REGION"
        print_success "Cluster deployed successfully"
    fi
}

# Function to scale cluster
scale_cluster() {
    print_status "Scaling cluster to ${CLUSTER_SIZE} nodes..."
    
    # Update cluster configuration
    local config_file="cluster-configs/${ENVIRONMENT}.yaml"
    if [ ! -f "$config_file" ]; then
        print_error "Cluster configuration file $config_file not found"
        exit 1
    fi
    
    # Update max count in configuration
    sed -i "s/MaxCount: [0-9]*/MaxCount: ${CLUSTER_SIZE}/g" "$config_file"
    
    # Update cluster
    pcluster update-cluster \
        --cluster-name "hpc-${ENVIRONMENT}" \
        --cluster-configuration "$config_file" \
        --region "$REGION"
    
    print_success "Cluster scaled to ${CLUSTER_SIZE} nodes"
}

# Function to test cluster
test_cluster() {
    print_status "Testing cluster functionality..."
    
    # Test SSH connection
    print_status "Testing SSH connection to head node..."
    pcluster ssh --cluster-name "hpc-${ENVIRONMENT}" --region "$REGION" \
        -c "echo 'SSH connection successful'"
    
    # Test EFA
    print_status "Testing EFA functionality..."
    pcluster ssh --cluster-name "hpc-${ENVIRONMENT}" --region "$REGION" \
        -c "fi_info -p efa"
    
    # Test MPI
    print_status "Testing MPI communication..."
    pcluster ssh --cluster-name "hpc-${ENVIRONMENT}" --region "$REGION" \
        -c "mpirun -np 2 --hostfile /opt/parallelcluster/shared/compute_ready_nodes hostname"
    
    # Test storage
    print_status "Testing storage performance..."
    pcluster ssh --cluster-name "hpc-${ENVIRONMENT}" --region "$REGION" \
        -c "dd if=/dev/zero of=/scratch/testfile bs=1M count=1000 && rm /scratch/testfile"
    
    # Test job submission
    print_status "Testing job submission..."
    pcluster ssh --cluster-name "hpc-${ENVIRONMENT}" --region "$REGION" \
        -c "sbatch --wrap='sleep 10' --job-name=test-job"
    
    print_success "Cluster tests completed successfully"
}

# Function to show cluster status
show_status() {
    print_status "Cluster status:"
    pcluster describe-cluster --cluster-name "hpc-${ENVIRONMENT}" --region "$REGION"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -r|--region)
            REGION="$2"
            shift 2
            ;;
        -a|--action)
            ACTION="$2"
            shift 2
            ;;
        -s|--cluster-size)
            CLUSTER_SIZE="$2"
            shift 2
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Validate action
case $ACTION in
    plan|apply|destroy|scale-up|scale-down)
        ;;
    *)
        print_error "Invalid action: $ACTION"
        show_usage
        exit 1
        ;;
esac

# Main execution
main() {
    print_status "Starting HPC infrastructure deployment..."
    print_status "Environment: $ENVIRONMENT"
    print_status "Region: $REGION"
    print_status "Action: $ACTION"
    
    if [ "$ACTION" = "scale-up" ] || [ "$ACTION" = "scale-down" ]; then
        print_status "Cluster size: $CLUSTER_SIZE"
    fi
    
    # Check prerequisites
    check_prerequisites
    
    # Validate environment
    validate_environment
    
    # Deploy infrastructure
    if [ "$ACTION" != "scale-up" ] && [ "$ACTION" != "scale-down" ]; then
        deploy_infrastructure
    fi
    
    # Deploy or scale cluster
    if [ "$ACTION" = "scale-up" ] || [ "$ACTION" = "scale-down" ]; then
        scale_cluster
    elif [ "$ACTION" = "apply" ]; then
        deploy_cluster
        test_cluster
    fi
    
    # Show status
    if [ "$ACTION" = "apply" ] || [ "$ACTION" = "scale-up" ] || [ "$ACTION" = "scale-down" ]; then
        show_status
    fi
    
    print_success "HPC infrastructure deployment completed successfully!"
}

# Run main function
main "$@"
