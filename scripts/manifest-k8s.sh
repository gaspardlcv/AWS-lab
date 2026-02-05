#!/bin/bash

set -e

# Charger les variables
if [ -f .env ]; then
    source .env
else
    echo "❌ Error: .env file not found!"
    echo "   Run: ./scripts/export-terraform-vars.sh"
    exit 1
fi

echo "📝 Generating Kubernetes manifests..."

# Créer le dossier k8s s'il n'existe pas
mkdir -p k8s

# 1. Namespace
cat > k8s/namespace.yaml <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: todo-app
  labels:
    name: todo-app
EOF

# 2. Secret avec MongoDB URI
cat > k8s/secret.yaml <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
  namespace: todo-app
type: Opaque
stringData:
  MONGODB_URI: ""
EOF

# 3. Service Account
cat > k8s/rbac.yaml <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: todo-app-sa
  namespace: todo-app
---
# ClusterRole avec admin complet - VULNÉRABILITÉ INTENTIONNELLE
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: todo-app-admin-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: todo-app-sa
  namespace: todo-app
EOF

# 4. Deployment
cat > k8s/deployment.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: todo-app
  namespace: todo-app
  labels:
    app: todo-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: todo-app
  template:
    metadata:
      labels:
        app: todo-app
    spec:
      serviceAccountName: todo-app-sa
      containers:
      - name: todo-app
        image: $ECR_IMAGE_LATEST
        imagePullPolicy: Always
        ports:
        - containerPort: 80
          name: http
        env:
        - name: MONGODB_URI
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: MONGODB_URI
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
        livenessProbe:
          httpGet:
            path: /health
            port: 80
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /health
            port: 80
          initialDelaySeconds: 10
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 3
EOF

# Service ClusterIP
cat > k8s/service.yaml <<EOF
apiVersion: v1
kind: Service
metadata:
  name: todo-app-service
  namespace: todo-app
  labels:
    app: todo-app
spec:
  type: ClusterIP 
  selector:
    app: todo-app
  ports:
  - port: 80
    targetPort: 3000
    protocol: TCP
    name: http
EOF

# Ingress - Crée automatiquement un ALB
cat > k8s/alb.yaml <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: todo-app-ingress
  namespace: todo-app
  annotations:
    # Configuration AWS Load Balancer Controller
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/healthcheck-path: /health
    alb.ingress.kubernetes.io/healthcheck-interval-seconds: '15'
    alb.ingress.kubernetes.io/healthcheck-timeout-seconds: '5'
    alb.ingress.kubernetes.io/success-codes: '200'
    alb.ingress.kubernetes.io/healthy-threshold-count: '2'
    alb.ingress.kubernetes.io/unhealthy-threshold-count: '2'
    # Tags pour l'ALB
    alb.ingress.kubernetes.io/tags: Environment=lab,ManagedBy=kubernetes
spec:
  ingressClassName: alb
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: todo-app-service
            port:
              number: 80
EOF

echo ""
echo "✅ Kubernetes manifests generated successfully!"
echo ""
echo "📋 Generated files:"
ls -lh k8s/*.yaml
echo ""
echo "🚀 To deploy, run:"
echo "   kubectl apply -f k8s/"