# GitHub OIDC Setup for AWS Authentication

This guide explains how to set up GitHub OIDC (OpenID Connect) for secure AWS authentication in GitHub Actions, eliminating the need for long-lived AWS access keys.

## Overview

GitHub OIDC allows GitHub Actions to assume AWS IAM roles directly without storing AWS credentials as secrets. This provides:

- **Enhanced Security**: No long-lived credentials stored in GitHub
- **Fine-grained Access**: Role-based permissions with conditions
- **Audit Trail**: Better tracking of AWS API calls
- **Automatic Rotation**: Temporary credentials with short expiration

## Prerequisites

- AWS CLI configured with appropriate permissions
- GitHub CLI (optional, for repository setup)
- Administrative access to the GitHub repository
- AWS account with IAM permissions

## Setup Steps

### 1. Run the Setup Script

#### For Linux/macOS:
```bash
# Update the script with your GitHub organization and repository
./scripts/setup-github-oidc.sh
```

#### For Windows PowerShell:
```powershell
# Update the script with your GitHub organization and repository
.\scripts\setup-github-oidc.ps1 -GitHubOrg "your-org" -GitHubRepo "hpc-networking"
```

### 2. Manual Setup (Alternative)

If you prefer to set up manually:

#### Step 1: Create OIDC Identity Provider
```bash
aws iam create-open-id-connect-provider \
    --url "https://token.actions.githubusercontent.com" \
    --thumbprint-list "6938fd4d98bab03faadb97b34396831e3780aea1" \
    --client-id-list "sts.amazonaws.com"
```

#### Step 2: Create Trust Policy
Create a file `trust-policy.json`:
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::ACCOUNT-ID:oidc-provider/token.actions.githubusercontent.com"
            },
            "Action": "sts:AssumeRole",
            "Condition": {
                "StringEquals": {
                    "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
                },
                "StringLike": {
                    "token.actions.githubusercontent.com:sub": "repo:YOUR-ORG/hpc-networking:*"
                }
            }
        }
    ]
}
```

#### Step 3: Create IAM Role
```bash
aws iam create-role \
    --role-name "GitHubActions-HPC-Networking-Role" \
    --assume-role-policy-document file://trust-policy.json \
    --description "Role for GitHub Actions HPC Networking deployment"
```

#### Step 4: Attach Policies
```bash
aws iam attach-role-policy \
    --role-name "GitHubActions-HPC-Networking-Role" \
    --policy-arn "arn:aws:iam::aws:policy/PowerUserAccess"
```

### 3. Configure GitHub Repository

#### Add Repository Secret
1. Go to your GitHub repository
2. Navigate to Settings → Secrets and variables → Actions
3. Click "New repository secret"
4. Name: `AWS_ROLE_ARN`
5. Value: The ARN from the setup script (e.g., `arn:aws:iam::123456789012:role/GitHubActions-HPC-Networking-Role`)

#### Using GitHub CLI (Optional)
```bash
gh secret set AWS_ROLE_ARN --body "arn:aws:iam::123456789012:role/GitHubActions-HPC-Networking-Role"
```

## Workflow Configuration

The GitHub Actions workflow has been updated to use OIDC:

```yaml
permissions:
  id-token: write
  contents: read

jobs:
  deploy:
    steps:
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
          aws-region: us-east-2
          role-session-name: GitHubActions-HPC-Deploy
```

## Security Considerations

### Trust Policy Conditions
The trust policy includes conditions to ensure security:

- **Audience**: Only `sts.amazonaws.com` can use the token
- **Subject**: Only the specific repository can assume the role
- **Repository**: Limited to `repo:YOUR-ORG/hpc-networking:*`

### IAM Permissions
The role uses `PowerUserAccess` which provides:
- Full access to AWS services except IAM user management
- Ability to create and manage resources
- Cost and billing access

For production, consider creating custom policies with minimal required permissions.

### Branch Protection
Consider adding branch protection rules:
- Require pull request reviews
- Require status checks
- Restrict pushes to main branch

## Troubleshooting

### Common Issues

1. **"The security token included in the request is invalid"**
   - Check that the OIDC provider is correctly configured
   - Verify the trust policy conditions
   - Ensure the repository name matches exactly

2. **"User is not authorized to perform sts:AssumeRole"**
   - Check IAM permissions for the GitHub Actions user
   - Verify the role ARN is correct
   - Ensure the trust policy allows the repository

3. **"No OpenIDConnect provider found"**
   - Re-run the OIDC provider creation step
   - Check the thumbprint is correct
   - Verify the provider URL

### Debugging

Enable debug logging in the workflow:
```yaml
- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
    aws-region: us-east-2
    role-session-name: GitHubActions-HPC-Deploy
    debug: true
```

### Verification

Test the setup by running a simple workflow:
```yaml
name: Test OIDC
on: workflow_dispatch
permissions:
  id-token: write
  contents: read
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
          aws-region: us-east-2
      - name: Test AWS access
        run: aws sts get-caller-identity
```

## Best Practices

1. **Use Environment-Specific Roles**: Create separate roles for dev, staging, and production
2. **Minimal Permissions**: Use least-privilege access principles
3. **Regular Audits**: Review and rotate roles periodically
4. **Monitor Usage**: Use CloudTrail to monitor role assumptions
5. **Branch Restrictions**: Limit role assumptions to specific branches

## Migration from Access Keys

If you're migrating from access keys:

1. Set up OIDC as described above
2. Update the workflow to use `role-to-assume`
3. Test the new configuration
4. Remove the old `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` secrets
5. Delete the old IAM user and access keys

## Support

For issues with this setup:
- Check AWS IAM documentation
- Review GitHub Actions OIDC documentation
- Consult the troubleshooting section above
