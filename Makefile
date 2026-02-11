.PHONY: help demo-all demo-vm demo-k8s demo-app demo-vulns check-prereq

# Variables
MONGODB_IP := $(shell cd terraform && terraform output -raw mongodb_public_ip 2>/dev/null)
MONGODB_PRIVATE_IP := $(shell cd terraform && terraform output -raw mongodb_private_ip 2>/dev/null)
MONGODB_PASSWORD := $(shell cd terraform && terraform output -raw mongodb_password 2>/dev/null)
BUCKET_NAME := $(shell cd terraform && terraform output -raw backup_bucket_name 2>/dev/null)
ALB_URL := $(shell kubectl get ingress todo-app-ingress -n todo-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)
POD_NAME := $(shell kubectl get pod -n todo-app -l app=todo-app -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
AWS_REGION := us-east-1

help: ## 📋 Afficher l'aide
	@echo "════════════════════════════════════════════════════════════════"
	@echo "           🎯 WIZ TECHNICAL EXERCISE DEMONSTRATION"
	@echo "════════════════════════════════════════════════════════════════"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "════════════════════════════════════════════════════════════════"

check-prereq: ## ✅ Vérifier les prérequis
	@echo "🔍 Checking prerequisites..."
	@echo ""
	@command -v terraform >/dev/null 2>&1 || { echo "❌ terraform not found"; exit 1; }
	@command -v kubectl >/dev/null 2>&1 || { echo "❌ kubectl not found"; exit 1; }
	@command -v aws >/dev/null 2>&1 || { echo "❌ aws CLI not found"; exit 1; }
	@command -v jq >/dev/null 2>&1 || { echo "❌ jq not found"; exit 1; }
	@echo "✅ All prerequisites installed"
	@echo ""
	@echo "📊 Current Infrastructure:"
	@echo "   MongoDB IP: $(MONGODB_IP)"
	@echo "   ALB URL: http://$(ALB_URL)"
	@echo "   S3 Bucket: $(BUCKET_NAME)"
	@echo ""

# ════════════════════════════════════════════════════════════════
# DÉMONSTRATION COMPLÈTE
# ════════════════════════════════════════════════════════════════

demo-all: check-prereq demo-vm demo-k8s demo-app demo-vulns ## 🎬 Démonstration complète (TOUT)
	@echo ""
	@echo "════════════════════════════════════════════════════════════════"
	@echo "           ✅ DÉMONSTRATION COMPLÈTE TERMINÉE"
	@echo "════════════════════════════════════════════════════════════════"

# ════════════════════════════════════════════════════════════════
# PARTIE 1 : VIRTUAL MACHINE MONGODB
# ════════════════════════════════════════════════════════════════

demo-vm: ## 🖥️  Démonstration VM MongoDB
	@echo ""
	@echo "════════════════════════════════════════════════════════════════"
	@echo "           1️⃣  VIRTUAL MACHINE MONGODB"
	@echo "════════════════════════════════════════════════════════════════"
	@$(MAKE) vm-version
	@$(MAKE) vm-ssh-exposed
	@$(MAKE) vm-iam-permissions
	@$(MAKE) vm-mongodb-version
	@$(MAKE) vm-mongodb-access
	@$(MAKE) vm-mongodb-auth
	@$(MAKE) vm-backups

vm-version: ## 🐧 Vérifier version Linux (1+ an)
	@echo ""
	@echo "📌 1.1 - Linux Version (Ubuntu 22.04 - Released April 2022)"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@ssh -i labus.pem -o StrictHostKeyChecking=no ubuntu@$(MONGODB_IP) "lsb_release -a" 2>/dev/null || echo "⚠️  Cannot SSH - check VM is running"
	@echo ""
	@echo "✅ Ubuntu 22.04.5 LTS (Plus de 1 an - REQUIS)"

vm-ssh-exposed: ## 🔓 Vérifier SSH exposé (0.0.0.0/0)
	@echo ""
	@echo "📌 1.2 - SSH Exposed to Internet (0.0.0.0/0) - VULNERABLE"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "Security Group Rules (Port 22):"
	@aws ec2 describe-security-groups \
		--group-ids $$(aws ec2 describe-instances \
			--filters "Name=tag:Name,Values=MongoDB-Server-Vulnerable" \
			--query 'Reservations[0].Instances[0].SecurityGroups[0].GroupId' \
			--output text --region $(AWS_REGION)) \
		--region $(AWS_REGION) \
		--query 'SecurityGroups[0].IpPermissions[?FromPort==`22`]' | jq
	@echo ""
	@echo "❌ VULNÉRABILITÉ: SSH accessible depuis 0.0.0.0/0"

vm-iam-permissions: ## 🔑 Vérifier permissions IAM excessives
	@echo ""
	@echo "📌 1.3 - IAM Permissions (Excessive) - VULNERABLE"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "IAM Policy for MongoDB EC2:"
	@aws iam get-role-policy \
		--role-name mongodb-ec2-role \
		--policy-name mongodb-excessive-permissions \
		--region $(AWS_REGION) | jq '.PolicyDocument.Statement'
	@echo ""
	@echo "❌ VULNÉRABILITÉ: Peut créer VMs (ec2:RunInstances) et utilisateurs IAM"

vm-mongodb-version: ## 📦 Vérifier version MongoDB (4.4 - obsolète)
	@echo ""
	@echo "📌 1.4 - MongoDB Version (4.4.x - Released 2020) - VULNERABLE"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@ssh -i labus.pem -o StrictHostKeyChecking=no ubuntu@$(MONGODB_IP) "mongod --version | head -1" 2>/dev/null
	@echo ""
	@echo "❌ VULNÉRABILITÉ: MongoDB 4.4 (Plus de 4 ans, CVE connus)"

vm-mongodb-access: ## 🔒 Vérifier accès MongoDB (Kubernetes only)
	@echo ""
	@echo "📌 1.5 - MongoDB Network Access (Kubernetes Only)"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "Security Group Rules (Port 27017):"
	@aws ec2 describe-security-groups \
		--group-ids $$(aws ec2 describe-instances \
			--filters "Name=tag:Name,Values=MongoDB-Server-Vulnerable" \
			--query 'Reservations[0].Instances[0].SecurityGroups[0].GroupId' \
			--output text --region $(AWS_REGION)) \
		--region $(AWS_REGION) \
		--query 'SecurityGroups[0].IpPermissions[?FromPort==`27017`]' | jq
	@echo ""
	@echo "✅ Port 27017 accessible UNIQUEMENT depuis le Security Group EKS"

vm-mongodb-auth: ## 🔐 Vérifier authentification MongoDB
	@echo ""
	@echo "📌 1.6 - MongoDB Authentication (Enabled)"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "MongoDB Config (authorization):"
	@ssh -i labus.pem -o StrictHostKeyChecking=no ubuntu@$(MONGODB_IP) "sudo grep -A 1 'security:' /etc/mongod.conf" 2>/dev/null
	@echo ""
	@echo "✅ Authentication activée (authorization: enabled)"

vm-backups: ## 💾 Vérifier backups automatiques S3
	@echo ""
	@echo "📌 1.7 - Automated Daily Backups to S3"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "Cron Job:"
	@ssh -i labus.pem -o StrictHostKeyChecking=no ubuntu@$(MONGODB_IP) "sudo crontab -l" 2>/dev/null
	@echo ""
	@echo "Backups in S3:"
	@aws s3 ls s3://$(BUCKET_NAME)/ --region $(AWS_REGION)
	@echo ""
	@echo "Public Access Configuration:"
	@aws s3api get-public-access-block --bucket $(BUCKET_NAME) --region $(AWS_REGION) | jq
	@echo ""
	@echo "❌ VULNÉRABILITÉ: Bucket S3 PUBLIC (lecture et listing autorisés)"

# ════════════════════════════════════════════════════════════════
# PARTIE 2 : KUBERNETES
# ════════════════════════════════════════════════════════════════

demo-k8s: ## ☸️  Démonstration Kubernetes
	@echo ""
	@echo "════════════════════════════════════════════════════════════════"
	@echo "           2️⃣  KUBERNETES CLUSTER"
	@echo "════════════════════════════════════════════════════════════════"
	@$(MAKE) k8s-private-subnet
	@$(MAKE) k8s-env-vars
	@$(MAKE) k8s-wizexercice
	@$(MAKE) k8s-cluster-admin
	@$(MAKE) k8s-ingress
	@$(MAKE) kubectl-demo

k8s-private-subnet: ## 🔐 Vérifier cluster dans subnet privé
	@echo ""
	@echo "📌 2.1 - EKS Cluster in Private Subnets"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "EKS Node Subnets:"
	@cd terraform && terraform output -json | jq -r '.private_sub1_id, .private_sub2_id'
	@echo ""
	@echo "Nodes in Private Subnets:"
	@kubectl get nodes -o wide
	@echo ""
	@echo "✅ Nodes déployés dans des subnets PRIVÉS"

k8s-env-vars: ## 🔑 Vérifier MONGODB_URI via env var
	@echo ""
	@echo "📌 2.2 - MongoDB URI via Environment Variable"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "Secret Kubernetes:"
	@kubectl get secret app-secrets -n todo-app -o yaml | grep -A 5 "data:"
	@echo ""
	@echo "Deployment Environment Variables:"
	@kubectl get deployment todo-app -n todo-app -o yaml | grep -A 10 "env:" | head -15
	@echo ""
	@echo "✅ MONGODB_URI injecté depuis un Secret Kubernetes"

k8s-wizexercice: ## 📄 Vérifier fichier wizexercice.txt
	@echo ""
	@echo "📌 2.3 - File wizexercice.txt in Container"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "Method 1: Via kubectl exec"
	@kubectl exec -n todo-app $(POD_NAME) -- cat /app/wizexercice.txt
	@echo ""
	@echo "Method 2: Via HTTP"
	@curl -s http://$(ALB_URL)/wizexercice.txt
	@echo ""
	@echo "✅ Fichier wizexercice.txt présent et accessible"

k8s-cluster-admin: ## ⚠️  Vérifier role cluster-admin (VULNÉRABLE)
	@echo ""
	@echo "📌 2.4 - Cluster-Admin Role Assignment - VULNERABLE"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "ClusterRoleBinding:"
	@kubectl get clusterrolebinding todo-app-admin-binding -o yaml | grep -A 10 "roleRef:"
	@echo ""
	@echo "Permissions du ServiceAccount:"
	@kubectl run test-perms --image=bitnami/kubectl --serviceaccount=todo-app-sa \
		--namespace=todo-app --restart=Never --rm -i -- \
		auth can-i --list 2>/dev/null | head -20 || echo "Test completed"
	@echo ""
	@echo "❌ VULNÉRABILITÉ: ServiceAccount a les permissions cluster-admin (contrôle total)"

k8s-ingress: ## 🌐 Vérifier Ingress + Load Balancer
	@echo ""
	@echo "📌 2.5 - Kubernetes Ingress + AWS Load Balancer"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "Service (ClusterIP):"
	@kubectl get svc -n todo-app
	@echo ""
	@echo "Ingress Resource:"
	@kubectl get ingress -n todo-app
	@echo ""
	@echo "Ingress Details:"
	@kubectl describe ingress todo-app-ingress -n todo-app | grep -A 5 "Annotations:"
	@echo ""
	@echo "✅ Application exposée via Ingress (ClusterIP + ALB auto-créé)"

kubectl-demo: ## 🎮 Démonstration kubectl complète
	@echo ""
	@echo "📌 2.6 - Kubectl Demonstration"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""
	@echo "All Resources in todo-app namespace:"
	@kubectl get all -n todo-app
	@echo ""
	@echo "Pod Details:"
	@kubectl get pods -n todo-app -o wide
	@echo ""
	@echo "Deployment YAML (excerpt):"
	@kubectl get deployment todo-app -n todo-app -o yaml | head -30
	@echo ""
	@echo "Recent Events:"
	@kubectl get events -n todo-app --sort-by='.lastTimestamp' | tail -10

# ════════════════════════════════════════════════════════════════
# PARTIE 3 : APPLICATION WEB
# ════════════════════════════════════════════════════════════════

demo-app: ## 🌍 Démonstration Application Web
	@echo ""
	@echo "════════════════════════════════════════════════════════════════"
	@echo "           3️⃣  WEB APPLICATION"
	@echo "════════════════════════════════════════════════════════════════"
	@$(MAKE) app-health
	@$(MAKE) app-api
	@$(MAKE) app-mongodb-proof
	@$(MAKE) app-create-todo
	@$(MAKE) app-verify-db

app-health: ## 💚 Health check
	@echo ""
	@echo "📌 3.1 - Application Health Check"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@curl -s http://$(ALB_URL)/health | jq
	@echo ""
	@echo "✅ Application healthy, MongoDB connected"

app-api: ## 📋 Lister les todos existants
	@echo ""
	@echo "📌 3.2 - List Existing Todos (API)"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@curl -s http://$(ALB_URL)/api/todos | jq
	@echo ""

app-mongodb-proof: ## 🔍 Logs prouvant connexion MongoDB
	@echo ""
	@echo "📌 3.3 - Proof of MongoDB Connection (Pod Logs)"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@kubectl logs -n todo-app $(POD_NAME) | grep -i mongodb
	@echo ""
	@echo "✅ Pod connecté à MongoDB"

app-create-todo: ## ➕ Créer un todo via API
	@echo ""
	@echo "📌 3.4 - Create Todo via API"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@curl -s -X POST http://$(ALB_URL)/api/todos \
		-H "Content-Type: application/json" \
		-d '{"text":"🎯 Démonstration Wiz - Todo créé le $(shell date +%Y-%m-%d\ %H:%M:%S)"}' | jq
	@echo ""
	@echo "✅ Todo créé via API"
	@echo ""
	@echo "Updated Todo List:"
	@curl -s http://$(ALB_URL)/api/todos | jq

app-verify-db: ## 🗄️  Vérifier données dans MongoDB
	@echo ""
	@echo "📌 3.5 - Verify Data in MongoDB Database"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "Connecting to MongoDB and querying todos collection..."
	@ssh -i labus.pem -o StrictHostKeyChecking=no ubuntu@$(MONGODB_IP) \
		"mongo -u admin -p '$(MONGODB_PASSWORD)' --authenticationDatabase admin --quiet --eval 'db.getSiblingDB(\"tododb\").todos.find().pretty()'"
	@echo ""
	@echo "✅ Données présentes dans MongoDB"

# ════════════════════════════════════════════════════════════════
# PARTIE 4 : VULNÉRABILITÉS
# ════════════════════════════════════════════════════════════════

demo-vulns: ## 🚨 Résumé des vulnérabilités
	@echo ""
	@echo "════════════════════════════════════════════════════════════════"
	@echo "           4️⃣  SECURITY VULNERABILITIES SUMMARY"
	@echo "════════════════════════════════════════════════════════════════"
	@$(MAKE) vuln-summary
	@$(MAKE) vuln-s3-public-demo
	@$(MAKE) vuln-exploit-chain

vuln-summary: ## 📊 Tableau récapitulatif
	@echo ""
	@echo "┌────────────────────────────────────────────────────────────────┐"
	@echo "│                  VULNERABILITIES MATRIX                        │"
	@echo "├────────────────────────────────────────────────────────────────┤"
	@echo "│ ID  │ Vulnerability          │ Severity │ Impact              │"
	@echo "├─────┼────────────────────────┼──────────┼─────────────────────┤"
	@echo "│ V1  │ S3 Bucket Public       │ 🔴 CRIT  │ Data Exfiltration   │"
	@echo "│ V2  │ SSH 0.0.0.0/0          │ 🔴 CRIT  │ VM Compromise       │"
	@echo "│ V3  │ IAM Excessive Perms    │ 🔴 CRIT  │ Privilege Escalation│"
	@echo "│ V4  │ K8s cluster-admin      │ 🔴 CRIT  │ Cluster Takeover    │"
	@echo "│ V5  │ MongoDB 4.4 (Outdated) │ 🟡 HIGH  │ CVE Exploitation    │"
	@echo "│ V6  │ Ubuntu 22.04 (No patch)│ 🟡 HIGH  │ Kernel Exploits     │"
	@echo "└─────┴────────────────────────┴──────────┴─────────────────────┘"
	@echo ""

vuln-s3-public-demo: ## 🔓 Démonstration S3 public
	@echo ""
	@echo "📌 4.1 - S3 Public Bucket Exploitation Demo"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "Attempting public access (NO AWS CREDENTIALS):"
	@echo ""
	@echo "Listing bucket contents:"
	@curl -s https://$(BUCKET_NAME).s3.$(AWS_REGION).amazonaws.com/ | head -20
	@echo ""
	@echo "❌ CRITIQUE: N'importe qui peut lister et télécharger les backups MongoDB"

vuln-exploit-chain: ## 🔗 Chaîne d'exploitation
	@echo ""
	@echo "📌 4.2 - Attack Chain Example"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""
	@echo "1. 🎯 Attacker discovers public S3 bucket"
	@echo "   → curl https://$(BUCKET_NAME).s3.$(AWS_REGION).amazonaws.com/"
	@echo ""
	@echo "2. 📥 Downloads MongoDB backup"
	@echo "   → curl -O https://$(BUCKET_NAME).s3.$(AWS_REGION).amazonaws.com/mongodb-backup-xxx.tar.gz"
	@echo ""
	@echo "3. 🔓 Extracts database"
	@echo "   → tar -xzf mongodb-backup-xxx.tar.gz"
	@echo "   → mongorestore backup/"
	@echo ""
	@echo "4. 💰 Exfiltrates all customer data"
	@echo "   → Full access to todos, users, credentials"
	@echo ""
	@echo "5. 🚀 Alternative: SSH Brute Force (0.0.0.0/0)"
	@echo "   → ssh ubuntu@$(MONGODB_IP)"
	@echo "   → Access to Secrets Manager → MongoDB credentials"
	@echo ""
	@echo "6. 🎮 Escalate with IAM permissions"
	@echo "   → Create IAM admin user"
	@echo "   → Launch EC2 instances for cryptomining"
	@echo ""
	@echo "7. ☸️  Kubernetes cluster-admin exploitation"
	@echo "   → Read all secrets across all namespaces"
	@echo "   → Deploy malicious pods"
	@echo "   → Access underlying EC2 nodes"
	@echo ""

# ════════════════════════════════════════════════════════════════
# UTILITAIRES
# ════════════════════════════════════════════════════════════════

open-app: ## 🌐 Ouvrir l'application dans le navigateur
	@echo "🌐 Opening application: http://$(ALB_URL)"
	@open http://$(ALB_URL) || xdg-open http://$(ALB_URL) || echo "Open manually: http://$(ALB_URL)"

ssh-mongodb: ## 🔌 SSH sur la VM MongoDB
	@ssh -i labus.pem -o StrictHostKeyChecking=no ubuntu@$(MONGODB_IP)

logs-app: ## 📜 Voir les logs de l'application
	@kubectl logs -n todo-app -l app=todo-app --tail=50 -f

shell-pod: ## 🐚 Shell dans un pod
	@kubectl exec -it -n todo-app $(POD_NAME) -- sh

info: ## ℹ️  Informations infrastructure
	@echo ""
	@echo "════════════════════════════════════════════════════════════════"
	@echo "           📊 INFRASTRUCTURE INFORMATION"
	@echo "════════════════════════════════════════════════════════════════"
	@echo ""
	@echo "MongoDB VM:"
	@echo "  Public IP:  $(MONGODB_IP)"
	@echo "  Private IP: $(MONGODB_PRIVATE_IP)"
	@echo "  SSH:        ssh -i labus.pem ubuntu@$(MONGODB_IP)"
	@echo ""
	@echo "S3 Bucket:"
	@echo "  Name:       $(BUCKET_NAME)"
	@echo "  URL:        https://$(BUCKET_NAME).s3.$(AWS_REGION).amazonaws.com/"
	@echo ""
	@echo "Kubernetes:"
	@echo "  Namespace:  todo-app"
	@echo "  Pod:        $(POD_NAME)"
	@echo ""
	@echo "Application:"
	@echo "  URL:        http://$(ALB_URL)"
	@echo "  Health:     http://$(ALB_URL)/health"
	@echo "  API:        http://$(ALB_URL)/api/todos"
	@echo ""

# Démonstrations individuelles rapides
quick-vm: vm-version vm-mongodb-version vm-backups ## ⚡ Demo VM rapide
quick-k8s: k8s-wizexercice kubectl-demo ## ⚡ Demo K8s rapide
quick-app: app-health app-api app-create-todo ## ⚡ Demo App rapide
quick-vulns: vuln-summary vuln-s3-public-demo ## ⚡ Demo Vulns rapide
