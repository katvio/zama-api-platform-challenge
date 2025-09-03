#!/bin/bash
# Setup Terraform S3 Backend for Zama API Platform Challenge
# This script creates S3 bucket and DynamoDB table for Terraform state management

set -e

# Configuration
export AWS_PROFILE="platform-admin"
export AWS_REGION="eu-west-1"
PROJECT_NAME="zama-api-platform"
ENVIRONMENT="dev"
BUCKET_NAME="${PROJECT_NAME}-terraform-state-$(date +%s)"
DYNAMODB_TABLE="${PROJECT_NAME}-terraform-locks"

echo "🚀 Setting up Terraform backend infrastructure..."
echo "AWS Profile: $AWS_PROFILE"
echo "AWS Region: $AWS_REGION"
echo "Bucket Name: $BUCKET_NAME"
echo "DynamoDB Table: $DYNAMODB_TABLE"

# Create S3 bucket for Terraform state
echo "📦 Creating S3 bucket for Terraform state..."
aws s3api create-bucket \
    --bucket "$BUCKET_NAME" \
    --region "$AWS_REGION" \
    --create-bucket-configuration LocationConstraint="$AWS_REGION" \
    --profile "$AWS_PROFILE"

# Enable versioning on the bucket
echo "🔄 Enabling versioning on S3 bucket..."
aws s3api put-bucket-versioning \
    --bucket "$BUCKET_NAME" \
    --versioning-configuration Status=Enabled \
    --profile "$AWS_PROFILE"

# Enable server-side encryption
echo "🔒 Enabling server-side encryption on S3 bucket..."
aws s3api put-bucket-encryption \
    --bucket "$BUCKET_NAME" \
    --server-side-encryption-configuration '{
        "Rules": [
            {
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                },
                "BucketKeyEnabled": true
            }
        ]
    }' \
    --profile "$AWS_PROFILE"

# Block public access
echo "🚫 Blocking public access to S3 bucket..."
aws s3api put-public-access-block \
    --bucket "$BUCKET_NAME" \
    --public-access-block-configuration \
        BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true \
    --profile "$AWS_PROFILE"

# Create lifecycle policy to manage old versions
echo "♻️ Setting up lifecycle policy..."
aws s3api put-bucket-lifecycle-configuration \
    --bucket "$BUCKET_NAME" \
    --lifecycle-configuration '{
        "Rules": [
            {
                "ID": "terraform-state-lifecycle",
                "Status": "Enabled",
                "Filter": {
                    "Prefix": ""
                },
                "NoncurrentVersionExpiration": {
                    "NoncurrentDays": 90
                },
                "AbortIncompleteMultipartUpload": {
                    "DaysAfterInitiation": 7
                }
            }
        ]
    }' \
    --profile "$AWS_PROFILE"

# Create DynamoDB table for state locking
echo "🔐 Creating DynamoDB table for state locking..."
aws dynamodb create-table \
    --table-name "$DYNAMODB_TABLE" \
    --attribute-definitions \
        AttributeName=LockID,AttributeType=S \
    --key-schema \
        AttributeName=LockID,KeyType=HASH \
    --provisioned-throughput \
        ReadCapacityUnits=5,WriteCapacityUnits=5 \
    --region "$AWS_REGION" \
    --profile "$AWS_PROFILE"

# Wait for table to be active
echo "⏳ Waiting for DynamoDB table to be active..."
aws dynamodb wait table-exists \
    --table-name "$DYNAMODB_TABLE" \
    --region "$AWS_REGION" \
    --profile "$AWS_PROFILE"

# Tag resources
echo "🏷️ Tagging resources..."
aws s3api put-bucket-tagging \
    --bucket "$BUCKET_NAME" \
    --tagging 'TagSet=[
        {Key=Project,Value=zama-api-platform},
        {Key=Environment,Value=dev},
        {Key=Purpose,Value=terraform-state},
        {Key=ManagedBy,Value=terraform}
    ]' \
    --profile "$AWS_PROFILE"

aws dynamodb tag-resource \
    --resource-arn "arn:aws:dynamodb:$AWS_REGION:$(aws sts get-caller-identity --query Account --output text --profile $AWS_PROFILE):table/$DYNAMODB_TABLE" \
    --tags \
        Key=Project,Value=zama-api-platform \
        Key=Environment,Value=dev \
        Key=Purpose,Value=terraform-locks \
        Key=ManagedBy,Value=terraform \
    --region "$AWS_REGION" \
    --profile "$AWS_PROFILE"

echo "✅ Terraform backend setup completed!"
echo ""
echo "📋 Backend Configuration:"
echo "S3 Bucket: $BUCKET_NAME"
echo "DynamoDB Table: $DYNAMODB_TABLE"
echo "Region: $AWS_REGION"
echo ""
echo "🔧 Update your Terraform backend configuration with:"
echo "bucket = \"$BUCKET_NAME\""
echo "dynamodb_table = \"$DYNAMODB_TABLE\""
echo "region = \"$AWS_REGION\""
echo ""
echo "💾 Save this information for your backend.tf files!"

# Save configuration to file
cat > ../terraform-backend-config.txt << EOF
# Terraform Backend Configuration
# Generated on $(date)

S3_BUCKET=$BUCKET_NAME
DYNAMODB_TABLE=$DYNAMODB_TABLE
AWS_REGION=$AWS_REGION
AWS_PROFILE=$AWS_PROFILE

# Backend block for Terraform:
terraform {
  backend "s3" {
    bucket         = "$BUCKET_NAME"
    dynamodb_table = "$DYNAMODB_TABLE"
    region         = "$AWS_REGION"
    encrypt        = true
  }
}
EOF

echo "💾 Backend configuration saved to terraform-backend-config.txt"
