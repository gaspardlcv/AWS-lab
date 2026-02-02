#!/bin/bash

set -e

echo "🔄 Exporting Terraform outputs to environment variables..."

# Se placer dans le dossier terraform
cd terraform

# Récupérer les outputs Terraform et créer le fichier .env
cat > ../.env <<EOF
# Generated automatically from Terraform outputs
# Date: $(date)

# MongoDB Configuration
export MONGODB_URI="$(terraform output -raw mongodb_uri)"
export MONGODB_PRIVATE_IP="$(terraform output -raw mongodb_private_ip)"

# ECR Configuration
export ECR_REPOSITORY_URL="$(terraform output -raw ecr_repository_url)"
export ECR_IMAGE_LATEST="${ECR_REPOSITORY_URL}:latest"

# AWS Configuration
export AWS_REGION="us-east-1"
export AWS_ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
export EKS_CLUSTER_NAME="$(terraform output -raw eks_cluster_name)"

# Load Balancer
export LOAD_BALANCER_DNS="$(terraform output -raw load_balancer_dns)"
export LOAD_BALANCER_URL="http://$(terraform output -raw load_balancer_dns)"
EOF

cd ..

echo "✅ Environment variables exported to .env file"
echo ""
echo "📋 To use these variables, run:"
echo "   source .env"
echo ""
echo "🔍 Current values:"
cat .env | grep -v "^#" | grep -v "^$"