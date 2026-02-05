#!/bin/bash
set -e

echo "📦 Installing AWS Load Balancer Controller"
echo ""

# Récupérer les variables Terraform
cd terraform
EKS_CLUSTER_NAME=$(terraform output -raw eks_cluster_name)
LB_CONTROLLER_ROLE_ARN=$(terraform output -raw lb_controller_role_arn)
AWS_REGION="eu-west-1"
VPC_ID=$(terraform output -raw vpc_id)
cd ..

# Configurer kubectl
echo "⚙️  Configuring kubectl..."
aws eks update-kubeconfig --name $EKS_CLUSTER_NAME --region $AWS_REGION

# Ajouter le repo Helm EKS
echo "📥 Adding EKS Helm repository..."
helm repo add eks https://aws.github.io/eks-charts
helm repo update

# Installer le AWS Load Balancer Controller
echo "🚀 Installing AWS Load Balancer Controller..."
helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
  --namespace kube-system \
  --set clusterName=$EKS_CLUSTER_NAME \
  --set serviceAccount.create=true \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=$LB_CONTROLLER_ROLE_ARN \
  --set region=$AWS_REGION \
  --set vpcId=$VPC_ID \
  --wait

# Vérifier l'installation
echo ""
echo "✅ Verifying installation..."
kubectl get deployment -n kube-system aws-load-balancer-controller

echo ""
echo "✅ AWS Load Balancer Controller installed successfully!"
echo ""
echo "📋 Next steps:"
echo "   1. Deploy your application with ClusterIP service"
echo "   2. Create an Ingress resource"
echo "   3. The ALB will be created automatically"
