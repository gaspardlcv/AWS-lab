# Network Outputs

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.myvpc.id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = aws_vpc.myvpc.cidr_block
}

output "public_subnet1_id" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public_sub1.id
}

output "public_subnet2_id" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public_sub2.id
}

output "private_sub1_id" {
  description = "List of private subnet IDs"
  value       = aws_subnet.private_sub1.id
}

output "private_sub2_id" {
  description = "List of private subnet IDs"
  value       = aws_subnet.private_sub2.id
}

output "public_subnet_cidr" {
  description = "List of public subnet CIDR blocks"
  value       = aws_subnet.public_sub1.cidr_block
}
output "public_subnet2_cidr" {
  description = "List of public subnet2 CIDR blocks"
  value       = aws_subnet.public_sub2.cidr_block
}

output "private_sub1_cidr" {
  description = "List of private subnet1 CIDR blocks"
  value       = aws_subnet.private_sub1.cidr_block
}
output "private_sub2_cidr" {
  description = "List of private subnet2 CIDR blocks"
  value       = aws_subnet.private_sub2.cidr_block
}

output "nat_gateway1_id" {
  description = "List of NAT Gateway IDs"
  value       = aws_nat_gateway.nat_gtw1.id
}
output "nat_gateway2_id" {
  description = "List of NAT Gateway2 IDs"
  value       = aws_nat_gateway.nat_gtw2.id
}

output "internet_gateway_id" {
  description = "Internet Gateway ID"
  value       = aws_internet_gateway.igw.id
}

// Out put de l'EKS

# URL du Load Balancer pour accéder à l'application
output "load_balancer_dns" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "load_balancer_url" {
  description = "Full URL to access the application"
  value       = "http://${aws_lb.main.dns_name}"
}

# ARN du Load Balancer pour la configuration Kubernetes Ingress
output "load_balancer_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.main.arn
}

# ARN du Target Group
output "target_group_arn" {
  description = "ARN of the Target Group"
  value       = aws_lb_target_group.app.arn
}

# Security Group ID de l'ALB
output "alb_security_group_id" {
  description = "Security Group ID of the ALB"
  value       = aws_security_group.alb_sg.id
}

# Informations MongoDB pour configuration
output "mongodb_private_ip" {
  description = "Private IP of MongoDB VM"
  value       = aws_instance.mongodb.private_ip
}

output "mongodb_public_ip" {
  description = "Public IP of MongoDB VM"
  value       = aws_instance.mongodb.public_ip
}

# Informations S3
output "backup_bucket_name" {
  description = "Name of the S3 bucket for MongoDB backups"
  value       = aws_s3_bucket.backups.id
}

output "backup_bucket_url" {
  description = "Public URL of the S3 bucket (VULNERABLE)"
  value       = "https://${aws_s3_bucket.backups.bucket}.s3.amazonaws.com"
}

# Informations EKS
output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "Endpoint of the EKS cluster"
  value       = module.eks.cluster_endpoint
}

output "configure_kubectl_command" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.region}"
}

# MongoDB URI
output "mongodb_uri" {
  description = "MongoDB connection URI"
  value       = "mongodb://admin:P%40ssw0rd123@${aws_instance.mongodb.private_ip}:27017/"
  sensitive   = true
}

# Format complet de l'image
output "ecr_image_url" {
  description = "Full ECR image URL with latest tag"
  value       = "${aws_ecr_repository.todo_app.repository_url}:latest"
}