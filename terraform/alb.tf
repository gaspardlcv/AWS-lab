
# IAM Policy pour AWS Load Balancer Controller
data "http" "lb_controller_iam_policy" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.7.0/docs/install/iam_policy.json"
}

resource "aws_iam_policy" "lb_controller" {
  name        = "AWSLoadBalancerControllerIAMPolicy"
  description = "IAM policy for AWS Load Balancer Controller"
  policy      = data.http.lb_controller_iam_policy.response_body
}

#  IAM Role pour le Service Account
module "lb_controller_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name = "aws-load-balancer-controller"

  attach_load_balancer_controller_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }

  tags = {
    Name = "aws-load-balancer-controller-irsa"
  }
}

# Outputs pour l'installation
output "lb_controller_role_arn" {
  description = "ARN of the IAM role for AWS Load Balancer Controller"
  value       = module.lb_controller_irsa.iam_role_arn
}