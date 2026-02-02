#!/usr/bin/env bash
set -euo pipefail

# Charger les variables d'environnement
if [ -f .env ]; then
  echo "📦 Loading environment variables from .env..."
  # shellcheck disable=SC1091
  source .env
else
  echo "❌ Error: .env file not found!"
  exit 1
fi

: "${ECR_REPOSITORY_URL:?❌ ECR_REPOSITORY_URL is not set}"
: "${AWS_REGION:?❌ AWS_REGION is not set}"

# Registry = partie avant le 1er "/"
REGISTRY="${ECR_REPOSITORY_URL%%/*}"
TAG="$(git rev-parse --short HEAD 2>/dev/null || echo manual)"

docker buildx create --name multiarch --driver docker-container --use 2>/dev/null || docker buildx use multiarch

echo "🔐 Logging into ECR registry..."
aws ecr get-login-password --region "${AWS_REGION}" | \
  docker login --username AWS --password-stdin "${REGISTRY}"

echo "🏗️  Building & pushing image..."
cd app

# Pour tes nodes EKS amd64 -> au minimum linux/amd64
# Tu peux aussi mettre linux/amd64,linux/arm64 si tu veux multi-arch.
docker buildx build \
  --platform linux/amd64 \
  -t "${ECR_REPOSITORY_URL}:latest" \
  -t "${ECR_REPOSITORY_URL}:${TAG}" \
  --push \
  .

echo ""
echo "✅ Image pushed successfully!"
echo "📦 ${ECR_REPOSITORY_URL}:latest"
echo "📦 ${ECR_REPOSITORY_URL}:${TAG}"
