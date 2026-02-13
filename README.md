#### AWS-lab Gaspard

**Reference Diagram:**
![diagram](./content/image.png)

###  Deploy project

## Step 1 : Launch Infra
Get Credentials AWS
Terraform init / plan / apply

## Step 2 : Deploy App in EKS + ALB
Either deploy :
- with shell deploy-with-ingress.sh
- with Action Github deploy-app

### Demo with Makefile

# Some Commands available 
make help

# Verify everything working
make check-prereq

# Test whole demo
make demo-all
make info           # show infrastructure
make demo-vm        # mongodb
make demo-k8s       #demo-app
make demo-vulns 

# Command Inside VMs
make shell-pod     # POD
make ssh-mongodb   # MongoDB

# Version MongoDB
make vm-mongodb-version

# Show wizexercice.txt
make k8s-wizexercice

# Create entry for DB
make app-create-todo

# Show S3 public
make vuln-s3-public-demo

# Show attack path
make vuln-exploit-chain
