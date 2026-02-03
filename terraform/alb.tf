locals {
  public_subnet_ids = [
    aws_subnet.public_sub1.id,
    aws_subnet.public_sub2.id,
  ]
}
# Security Group pour l'ALB
resource "aws_security_group" "alb_sg" {
  name        = "lab-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = aws_vpc.myvpc.id

  # HTTP depuis Internet
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP from anywhere"
  }

  # HTTPS depuis Internet
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS from anywhere"
  }

  # Trafic sortant vers le cluster Kubernetes
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "lab-alb-sg"
  }
}

# Application Load Balancer
resource "aws_lb" "main" {
  name               = "lab-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = local.public_subnet_ids

  enable_deletion_protection = false
  enable_http2              = true
  enable_cross_zone_load_balancing = true

  tags = {
    Name        = "lab-alb"
    Environment = "demo"
  }
}

# Target Group pour l'application Kubernetes
resource "aws_lb_target_group" "app" {
  name        = "lab-tg"
  port        = 30080              # ← MODIFIÉ : Port du NodePort Kubernetes
  protocol    = "HTTP"
  vpc_id      = aws_vpc.myvpc.id
  target_type = "instance"         # ← MODIFIÉ : De "ip" à "instance"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/"      # ← Vérifiez que votre app répond sur /
    protocol            = "HTTP"
    port                = "30080"  # ← AJOUTÉ : Port pour le health check
    matcher             = "200-299"
  }

  deregistration_delay = 30

  tags = {
    Name = "lab-target-group"
  }
}

# Listener HTTP (port 80)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }

  tags = {
    Name = "http-listener"
  }
}
# resource "aws_lb_listener" "https" {
#   load_balancer_arn = aws_lb.main.arn
#   port              = 443
#   protocol          = "HTTPS"
#   ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
#   certificate_arn   = aws_acm_certificate.main.arn  # Référence à créer

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.app.arn
#   }

#   tags = {
#     Name = "https-listener"
#   }
# }

# Data source pour récupérer les instances EKS
data "aws_instances" "eks_nodes" {
  filter {
    name   = "tag:eks:cluster-name"
    values = [module.eks.cluster_name]
  }

  filter {
    name   = "instance-state-name"
    values = ["running"]
  }

  depends_on = [module.eks]
}

# Attacher automatiquement les worker nodes au Target Group
resource "aws_lb_target_group_attachment" "eks_nodes" {
  count            = length(data.aws_instances.eks_nodes.ids)
  target_group_arn = aws_lb_target_group.app.arn
  target_id        = data.aws_instances.eks_nodes.ids[count.index]
  port             = 30080

  depends_on = [
    aws_lb_target_group.app,
    module.eks
  ]
}