#!/bin/bash

set -e

echo "🚀 Starting full deployment process..."
echo ""

# Charger les variables
if [ -f .env ]; then
    source .env
else
    echo "❌ Error: .env file not found!"
    echo "   Run: ./scripts/export-terraform-vars.sh first"
    exit 1
fi

# Étape 1 : Build et Push
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 Step 1/4: Building and pushing Docker image"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
./scripts/build-and-push.sh

# Étape 2 : Générer les manifests Kubernetes
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 Step 2/4: Generating Kubernetes manifests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
./scripts/manifest-k8s.sh

# Étape 3 : Configurer kubectl
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "⚙️  Step 3/4: Configuring kubectl"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
aws eks update-kubeconfig --name $EKS_CLUSTER_NAME --region $AWS_REGION

# Étape 4 : Déployer sur Kubernetes
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "☸️  Step 4/4: Deploying to Kubernetes"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
kubectl apply -f k8s/

# Attendre que le déploiement soit prêt
echo ""
echo "⏳ Waiting for deployment to be ready..."
kubectl rollout status deployment/todo-app -n todo-app --timeout=5m

# Afficher le statut
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Deployment completed successfully!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📊 Pod status:"
kubectl get pods -n todo-app
echo ""
echo "🌐 Service status:"
kubectl get svc -n todo-app
echo ""
echo "🔗 Application URL:"
echo "   $LOAD_BALANCER_URL"
echo ""
echo "🔍 Verify wizexercise.txt in running pod:"
POD_NAME=$(kubectl get pods -n todo-app -l app=todo-app -o jsonpath='{.items[0].metadata.name}')
echo "   kubectl exec -it $POD_NAME -n todo-app -- cat /app/wizexercise.txt"