locals {
  private_subnet_ids = [
    aws_subnet.private_sub1.id,
    aws_subnet.private_sub2.id,
  ]
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = "lab-cluster"
  cluster_version = "1.29"

  vpc_id     = aws_vpc.myvpc.id
  subnet_ids = local.private_subnet_ids

  # Configuration du cluster
  cluster_endpoint_public_access = true

  eks_managed_node_groups = {
    main = {
      min_size     = 2
      max_size     = 3
      desired_size = 2

      instance_types = ["t3.medium"]
    }
  }

  # CloudWatch Logging pour l'audit
  cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

# Security Group Rule ALB - EKS
resource "aws_security_group_rule" "eks_nodes_from_alb" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = module.eks.node_security_group_id
  cidr_blocks              = [var.cidr]
  description              = "Allow HTTP traffic from ALB to EKS nodes"
}