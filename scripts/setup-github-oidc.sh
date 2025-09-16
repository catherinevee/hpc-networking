#!/bin/bash
# Setup GitHub OIDC for AWS Authentication

set -euo pipefail

# Configuration
GITHUB_ORG="your-github-org"
GITHUB_REPO="hpc-networking"
AWS_REGION="us-east-2"
ROLE_NAME="GitHubActions-HPC-Networking-Role"

# Get GitHub repository info
REPO_URL="https://github.com/${GITHUB_ORG}/${GITHUB_REPO}"
OIDC_THUMBPRINT="6938fd4d98bab03faadb97b34396831e3780aea1"

echo "Setting up GitHub OIDC for AWS authentication..."

# 1. Create OIDC Identity Provider
echo "Creating OIDC Identity Provider..."
aws iam create-open-id-connect-provider \
    --url "https://token.actions.githubusercontent.com" \
    --thumbprint-list "${OIDC_THUMBPRINT}" \
    --client-id-list "sts.amazonaws.com" \
    --region "${AWS_REGION}" || echo "OIDC provider may already exist"

# 2. Create trust policy
echo "Creating trust policy..."
cat > trust-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):oidc-provider/token.actions.githubusercontent.com"
            },
            "Action": "sts:AssumeRole",
            "Condition": {
                "StringEquals": {
                    "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
                },
                "StringLike": {
                    "token.actions.githubusercontent.com:sub": "repo:${GITHUB_ORG}/${GITHUB_REPO}:*"
                }
            }
        }
    ]
}
EOF

# 3. Create IAM role
echo "Creating IAM role..."
aws iam create-role \
    --role-name "${ROLE_NAME}" \
    --assume-role-policy-document file://trust-policy.json \
    --description "Role for GitHub Actions HPC Networking deployment"

# 4. Attach necessary policies
echo "Attaching policies..."
aws iam attach-role-policy \
    --role-name "${ROLE_NAME}" \
    --policy-arn "arn:aws:iam::aws:policy/PowerUserAccess"

# 5. Get role ARN
ROLE_ARN=$(aws iam get-role --role-name "${ROLE_NAME}" --query 'Role.Arn' --output text)
echo "Role ARN: ${ROLE_ARN}"

# 6. Clean up
rm -f trust-policy.json

echo "Setup complete! Add this to your GitHub repository secrets:"
echo "AWS_ROLE_ARN: ${ROLE_ARN}"
