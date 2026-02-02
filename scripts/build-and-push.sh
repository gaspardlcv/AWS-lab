#!/bin/bash

set -e

# Charger les variables d'environnement
if [ -f .env ]; then
    echo "📦 Loading environment variables from .env..."
    source .env
else
    echo "❌ Error: .env file not found!"
    echo "   Run: ./scripts/export-terraform-vars.sh"
    exit 1
fi

# Vérifier que les variables sont définies
if [ -z "$ECR_REPOSITORY_URL" ]; then
    echo "❌ Error: ECR_REPOSITORY_URL is not set!"
    exit 1
fi

echo "🔐 Logging into ECR..."
aws ecr get-login-password --region $AWS_REGION | \
  docker login --username AWS --password-stdin $ECR_REPOSITORY_URL

echo "🏗️  Building Docker image..."
cd app/
docker build -t todo-app:latest .

echo "🏷️  Tagging image..."
docker tag todo-app:latest $ECR_REPOSITORY_URL:latest
docker tag todo-app:latest $ECR_REPOSITORY_URL:$(git rev-parse --short HEAD 2>/dev/null || echo "manual")

echo "📤 Pushing to ECR..."
docker push $ECR_REPOSITORY_URL:latest
docker push $ECR_REPOSITORY_URL:$(git rev-parse --short HEAD 2>/dev/null || echo "manual")

echo ""
echo "✅ Image pushed successfully!"
echo "📦 Image URL: $ECR_REPOSITORY_URL:latest"
echo ""
echo "🔍 Verify the file wizexercise.txt is in the image:"
echo "   docker run --rm $ECR_REPOSITORY_URL:latest cat /app/wizexercise.txt"