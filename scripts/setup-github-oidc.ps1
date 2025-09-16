# Setup GitHub OIDC for AWS Authentication
param(
    [Parameter(Mandatory=$true)]
    [string]$GitHubOrg,
    
    [Parameter(Mandatory=$true)]
    [string]$GitHubRepo,
    
    [string]$AWSRegion = "us-east-2",
    [string]$RoleName = "GitHubActions-HPC-Networking-Role"
)

# Configuration
$RepoUrl = "https://github.com/$GitHubOrg/$GitHubRepo"
$OidcThumbprint = "6938fd4d98bab03faadb97b34396831e3780aea1"

Write-Host "Setting up GitHub OIDC for AWS authentication..." -ForegroundColor Green

try {
    # 1. Create OIDC Identity Provider
    Write-Host "Creating OIDC Identity Provider..." -ForegroundColor Yellow
    try {
        aws iam create-open-id-connect-provider `
            --url "https://token.actions.githubusercontent.com" `
            --thumbprint-list $OidcThumbprint `
            --client-id-list "sts.amazonaws.com" `
            --region $AWSRegion
    } catch {
        Write-Host "OIDC provider may already exist" -ForegroundColor Yellow
    }

    # 2. Get AWS Account ID
    $AccountId = aws sts get-caller-identity --query Account --output text

    # 3. Create trust policy
    Write-Host "Creating trust policy..." -ForegroundColor Yellow
    $TrustPolicyJson = @"
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::$AccountId`:oidc-provider/token.actions.githubusercontent.com"
            },
            "Action": "sts:AssumeRole",
            "Condition": {
                "StringEquals": {
                    "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
                },
                "StringLike": {
                    "token.actions.githubusercontent.com:sub": "repo:$GitHubOrg/$GitHubRepo`:*"
                }
            }
        }
    ]
}
"@

    $TrustPolicyJson | Out-File -FilePath "trust-policy.json" -Encoding UTF8

    # 4. Create IAM role
    Write-Host "Creating IAM role..." -ForegroundColor Yellow
    aws iam create-role `
        --role-name $RoleName `
        --assume-role-policy-document file://trust-policy.json `
        --description "Role for GitHub Actions HPC Networking deployment"

    # 5. Attach necessary policies
    Write-Host "Attaching policies..." -ForegroundColor Yellow
    aws iam attach-role-policy `
        --role-name $RoleName `
        --policy-arn "arn:aws:iam::aws:policy/PowerUserAccess"

    # 6. Get role ARN
    $RoleArn = aws iam get-role --role-name $RoleName --query 'Role.Arn' --output text
    Write-Host "Role ARN: $RoleArn" -ForegroundColor Green

    # 7. Clean up
    Remove-Item -Path "trust-policy.json" -Force

    Write-Host "Setup complete! Add this to your GitHub repository secrets:" -ForegroundColor Green
    Write-Host "AWS_ROLE_ARN: $RoleArn" -ForegroundColor Cyan

} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
