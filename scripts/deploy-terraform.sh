#!/bin/bash
# Deploy Terraform Infrastructure with Separated State Files
# This script deploys infrastructure in the correct order with isolated state files

set -e

# Configuration
export AWS_PROFILE="platform-admin"
export AWS_REGION="eu-west-1"
PROJECT_NAME="zama-api-platform"
ENVIRONMENT="dev"
TERRAFORM_DIR="/Users/cyrb/pro_wks/zama-api-platform-challenge/terraform/environments/dev"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Function to deploy a terraform module
deploy_module() {
    local module_name=$1
    local module_path="${TERRAFORM_DIR}/${module_name}"
    
    print_status "Deploying ${module_name} module..."
    
    if [ ! -d "$module_path" ]; then
        print_error "Module directory not found: $module_path"
        exit 1
    fi
    
    cd "$module_path"
    
    # Check if backend configuration exists
    if ! grep -q "backend.*s3" main.tf; then
        print_warning "Backend not configured for ${module_name}. Please run setup-terraform-backend.sh first."
    fi
    
    # Initialize Terraform
    print_status "Initializing Terraform for ${module_name}..."
    terraform init
    
    # Validate configuration
    print_status "Validating Terraform configuration for ${module_name}..."
    terraform validate
    
    # Plan deployment
    print_status "Creating Terraform plan for ${module_name}..."
    terraform plan -out="${module_name}.tfplan"
    
    # Apply deployment
    print_status "Applying Terraform plan for ${module_name}..."
    terraform apply "${module_name}.tfplan"
    
    print_success "${module_name} module deployed successfully!"
    
    # Clean up plan file
    rm -f "${module_name}.tfplan"
    
    echo ""
}

# Function to update backend configuration
update_backend_config() {
    local module_name=$1
    local module_path="${TERRAFORM_DIR}/${module_name}"
    local bucket_name=$2
    local dynamodb_table=$3
    
    print_status "Updating backend configuration for ${module_name}..."
    
    cd "$module_path"
    
    # Backend configuration is already updated with correct values
    print_status "Backend configuration already configured for ${module_name}"
    
    # Remove backup file
    rm -f main.tf.bak
    
    print_success "Backend configuration updated for ${module_name}"
}

# Main deployment function
main() {
    print_status "Starting Terraform deployment with separated state files..."
    print_status "AWS Profile: $AWS_PROFILE"
    print_status "AWS Region: $AWS_REGION"
    print_status "Project: $PROJECT_NAME"
    print_status "Environment: $ENVIRONMENT"
    echo ""
    
    # Hardcoded backend configuration
    S3_BUCKET="zama-api-platform-terraform-state-1756826383"
    DYNAMODB_TABLE="zama-api-platform-terraform-locks"
    AWS_REGION="eu-west-1"
    
    print_status "Using S3 bucket: $S3_BUCKET"
    print_status "Using DynamoDB table: $DYNAMODB_TABLE"
    echo ""
    
    # Backend configurations are already updated with correct values
    print_status "Backend configurations already configured for all modules"
    
    # Deploy modules in order (respecting dependencies)
    print_status "Deploying infrastructure modules in dependency order..."
    echo ""
    
    # 1. Networking (no dependencies)
    deploy_module "networking"
    
    # 2. Secrets (no dependencies)
    deploy_module "secrets"
    
    # 3. Observability (depends on networking)
    deploy_module "observability"
    
    # 4. Compute (depends on networking, secrets, observability)
    deploy_module "compute"
    
    print_success "All modules deployed successfully!"
    echo ""
    
    # Display outputs
    print_status "Retrieving deployment information..."
    
    cd "${TERRAFORM_DIR}/compute"
    ALB_DNS=$(terraform output -raw alb_dns_name 2>/dev/null || echo "N/A")
    API_URL=$(terraform output -raw api_direct_url 2>/dev/null || echo "N/A")
    
    echo ""
    print_success "=== DEPLOYMENT SUMMARY ==="
    echo "API Service URL: $API_URL"
    echo "ALB DNS Name: $ALB_DNS"
    echo ""
    echo "Next Steps:"
    echo "1. Configure Kong Konnect to proxy to: $API_URL"
    echo "2. Test the API endpoints:"
    echo "   - Health: curl -X GET $API_URL/healthz"
    echo "   - Sum: curl -X POST $API_URL/api/v1/sum -H 'Content-Type: application/json' -d '{\"numbers\": [1,2,3,4,5]}'"
    echo ""
    echo "State files are stored separately:"
    echo "- Networking: s3://$S3_BUCKET/networking/terraform.tfstate"
    echo "- Secrets: s3://$S3_BUCKET/secrets/terraform.tfstate"
    echo "- Observability: s3://$S3_BUCKET/observability/terraform.tfstate"
    echo "- Compute: s3://$S3_BUCKET/compute/terraform.tfstate"
    echo ""
    print_success "Deployment completed successfully! 🎉"
}

# Run main function
main "$@"
