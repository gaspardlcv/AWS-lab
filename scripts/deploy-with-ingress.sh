#!/bin/bash
set -e

echo "🚀 Complete Deployment with AWS Load Balancer Controller"
echo ""

# ============================================
# ÉTAPE 1: Terraform Apply
# ============================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 STEP 1/6: Deploying Infrastructure with Terraform"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

cd terraform

# Ajouter terraform-lb-controller.tf au projet
if [ ! -f "aws-lb-controller.tf" ]; then
  echo "⚠️  Adding aws-lb-controller.tf to Terraform..."
  cp ../outputs/terraform-lb-controller.tf ./aws-lb-controller.tf
fi

terraform init
terraform apply -auto-approve

# Récupérer les outputs
MONGODB_URI=$(terraform output -raw mongodb_uri)
ECR_REPO_URL=$(terraform output -raw ecr_repository_url)
EKS_CLUSTER_NAME=$(terraform output -raw eks_cluster_name)
LB_CONTROLLER_ROLE_ARN=$(terraform output -raw lb_controller_role_arn)
VPC_ID=$(terraform output -raw vpc_id)
AWS_REGION="eu-west-1"

cd ..

echo "✅ Infrastructure deployed"

# ============================================
# ÉTAPE 2: Installer AWS Load Balancer Controller
# ============================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎛️  STEP 2/6: Installing AWS Load Balancer Controller"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Configurer kubectl
aws eks update-kubeconfig --name $EKS_CLUSTER_NAME --region $AWS_REGION

# Vérifier si déjà installé
if kubectl get deployment -n kube-system aws-load-balancer-controller &>/dev/null; then
  echo "⚠️  AWS Load Balancer Controller already installed, skipping..."
else
  echo "📥 Adding EKS Helm repository..."
  helm repo add eks https://aws.github.io/eks-charts
  helm repo update

  echo "🚀 Installing AWS Load Balancer Controller..."
  helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
    --namespace kube-system \
    --set clusterName=$EKS_CLUSTER_NAME \
    --set serviceAccount.create=true \
    --set serviceAccount.name=aws-load-balancer-controller \
    --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=$LB_CONTROLLER_ROLE_ARN \
    --set region=$AWS_REGION \
    --set vpcId=$VPC_ID \
    --wait

  echo "✅ AWS Load Balancer Controller installed"
fi

# ============================================
# ÉTAPE 3: Build et Push Docker Image
# ============================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🐳 STEP 3/6: Building and Pushing Docker Image"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

REGISTRY="${ECR_REPO_URL%%/*}"
aws ecr get-login-password --region $AWS_REGION | \
  docker login --username AWS --password-stdin $REGISTRY

cd app
docker buildx build \
  --platform linux/amd64 \
  -t "${ECR_REPO_URL}:latest" \
  --push \
  .
cd ..

echo "✅ Image pushed to ECR"

# ============================================
# ÉTAPE 4: Déployer Kubernetes avec Ingress
# ============================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "☸️  STEP 4/6: Deploying Kubernetes Resources"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Remplacer l'URL de l'image
sed "s|YOUR_ECR_REPO_URL:latest|${ECR_REPO_URL}:latest|g" \
  k8s/manifests-ingress.yaml > k8s/manifests-deployed.yaml

kubectl apply -f k8s/manifests-deployed.yaml

echo "✅ Kubernetes resources deployed"

# ============================================
# ÉTAPE 5: Injecter le secret MongoDB
# ============================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔐 STEP 5/6: Injecting MongoDB URI Secret"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

kubectl wait --for=jsonpath='{.status.phase}'=Active namespace/todo-app --timeout=30s

kubectl create secret generic app-secrets \
  --from-literal=MONGODB_URI="$MONGODB_URI" \
  --namespace=todo-app \
  --dry-run=client -o yaml | kubectl apply -f -

echo "✅ Secret injected"

kubectl rollout restart deployment/todo-app -n todo-app
kubectl rollout status deployment/todo-app -n todo-app --timeout=5m

# ============================================
# ÉTAPE 6: Attendre la création de l'ALB
# ============================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "⏳ STEP 6/6: Waiting for ALB to be created..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "Waiting for Ingress to get an address..."
for i in {1..60}; do
  ALB_DNS=$(kubectl get ingress todo-app-ingress -n todo-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
  if [ -n "$ALB_DNS" ]; then
    echo "✅ ALB created: $ALB_DNS"
    break
  fi
  echo "Still waiting... ($i/60)"
  sleep 10
done

if [ -z "$ALB_DNS" ]; then
  echo "⚠️  ALB not ready yet. Check with: kubectl get ingress -n todo-app"
else
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Deployment Complete!"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "📊 Application Status:"
  kubectl get pods,svc,ingress -n todo-app
  echo ""
  echo "🌐 Application URL: http://$ALB_DNS"
  echo ""
  echo "📋 Useful commands:"
  echo "   kubectl logs -n todo-app -l app=todo-app"
  echo "   curl http://$ALB_DNS/health"
  echo "   kubectl describe ingress todo-app-ingress -n todo-app"
fi
