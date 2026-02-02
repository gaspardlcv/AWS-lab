# AWS-lab

# Constraints

**Reference Diagram:**
![diagram](./content/image.png)

export AWS_DEFAULT_REGION="us-west-2"

nano ~/.aws/credentials

aws sts get-caller-identity

terraform init
terraform plan
terraform apply

Vérification fichier docker

3.4 Vérification du fichier dans le container
Ajoutez cette section dans votre documentation/présentation :
bash# Méthode 1 : Vérifier lors du build
docker build -t todo-app .
docker run --rm todo-app cat /app/wizexercise.txt

# Méthode 2 : Vérifier dans le pod Kubernetes en production
kubectl exec -it <pod-name> -- cat /app/wizexercise.txt

# Déploiement Terraform 

cd terraform
terraform init
terraform apply
cd ..

# Récupérez les variables d'environnement 

# 1. Générer le fichier .env depuis Terraform
./scripts/get-tf-vars-env.sh

# 2. Charger les variables dans votre session
source .env

# Montrer les variables d'environnement
cat .env

# 3. Vérifier que ça fonctionne
echo $MONGODB_URI
echo $ECR_IMAGE_LATEST

# 4. Faire le déploiement du Docker
./scripts/deploy.sh

kubectl get nodes

# Vérifier wizexercise.txt
POD=$(kubectl get pod -n todo-app -l app=todo-app -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it $POD -n todo-app -- cat /app/wizexercise.txt

# Accéder à l'application
curl $LOAD_BALANCER_URL

aws ecr batch-delete-image \
  --repository-name todo-app \
  --region eu-west-1 \
  --image-ids imageTag=latest

kubectl delete namespace todo-app 