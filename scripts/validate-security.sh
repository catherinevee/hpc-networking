#!/bin/bash
# Security Validation Script for HPC Networking Module
# Validates security configurations and IAM policies

set -e

echo "🔒 Validating HPC Networking Module Security Configuration..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check if a file exists and contains specific patterns
check_file_pattern() {
    local file="$1"
    local pattern="$2"
    local description="$3"
    
    if grep -q "$pattern" "$file"; then
        echo -e "${RED}❌ $description found in $file${NC}"
        return 1
    else
        echo -e "${GREEN}✅ $description not found in $file${NC}"
        return 0
    fi
}

# Function to check if a file contains required patterns
check_required_pattern() {
    local file="$1"
    local pattern="$2"
    local description="$3"
    
    if grep -q "$pattern" "$file"; then
        echo -e "${GREEN}✅ $description found in $file${NC}"
        return 0
    else
        echo -e "${RED}❌ $description not found in $file${NC}"
        return 1
    fi
}

# Initialize error counter
errors=0

echo "📋 Checking security group configurations..."

# Check security.tf for overly permissive rules
if check_file_pattern "security.tf" "from_port = 0.*to_port = 0.*protocol = \"-1\"" "Overly permissive security group rule"; then
    ((errors++))
fi

# Check for specific EFA ports instead of all traffic
if check_required_pattern "security.tf" "18515.*18516" "EFA communication ports"; then
    echo -e "${GREEN}✅ EFA ports properly configured${NC}"
else
    echo -e "${RED}❌ EFA ports not properly configured${NC}"
    ((errors++))
fi

echo "🔐 Checking IAM policies..."

# Check for least privilege implementation
if check_file_pattern "security.tf" "Resource = \"\\*\"" "Wildcard resource in IAM policy"; then
    ((errors++))
fi

# Check for specific resource ARNs
if check_required_pattern "security.tf" "arn:aws:ec2:" "Specific resource ARNs in IAM policy"; then
    echo -e "${GREEN}✅ IAM policy uses specific resource ARNs${NC}"
else
    echo -e "${RED}❌ IAM policy should use specific resource ARNs${NC}"
    ((errors++))
fi

echo "🔑 Checking encryption configurations..."

# Check for KMS key creation
if check_required_pattern "security.tf" "aws_kms_key" "KMS key resource"; then
    echo -e "${GREEN}✅ KMS encryption key configured${NC}"
else
    echo -e "${RED}❌ KMS encryption key not configured${NC}"
    ((errors++))
fi

# Check for prevent_destroy lifecycle rules
if check_required_pattern "security.tf" "prevent_destroy = true" "Resource protection lifecycle rule"; then
    echo -e "${GREEN}✅ Resource protection configured${NC}"
else
    echo -e "${RED}❌ Resource protection not configured${NC}"
    ((errors++))
fi

echo "🏷️ Checking variable validations..."

# Check for sensitive variable marking
if check_required_pattern "variables.tf" "sensitive = true" "Sensitive variable marking"; then
    echo -e "${GREEN}✅ Sensitive variables properly marked${NC}"
else
    echo -e "${RED}❌ Sensitive variables not properly marked${NC}"
    ((errors++))
fi

# Check for input validation
if check_required_pattern "variables.tf" "validation {" "Input validation blocks"; then
    echo -e "${GREEN}✅ Input validation configured${NC}"
else
    echo -e "${RED}❌ Input validation not configured${NC}"
    ((errors++))
fi

echo "🔧 Checking resource naming conventions..."

# Check for consistent naming
if check_required_pattern "locals.tf" "resource_names" "Resource naming convention"; then
    echo -e "${GREEN}✅ Resource naming convention implemented${NC}"
else
    echo -e "${RED}❌ Resource naming convention not implemented${NC}"
    ((errors++))
fi

echo "📊 Summary:"

if [ $errors -eq 0 ]; then
    echo -e "${GREEN}🎉 All security validations passed!${NC}"
    echo -e "${GREEN}✅ Module is ready for production deployment${NC}"
    exit 0
else
    echo -e "${RED}❌ Found $errors security issue(s) that need to be addressed${NC}"
    echo -e "${YELLOW}⚠️  Please review and fix the issues above before deployment${NC}"
    exit 1
fi
