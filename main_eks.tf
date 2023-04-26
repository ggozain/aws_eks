data "tfe_outputs" "vpc" {
  organization = var.tfcloud_organization
  workspace    = var.tfcloud_workspace_vpc
}

data "tfe_outputs" "oidc" {
  organization = var.tfcloud_organization
  workspace    = var.tfcloud_workspace_oidc
}

data "tls_certificate" "tfc_certificate" {
  url = "https://${var.tfc_hostname}"
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "18.29.0"

  cluster_name    = var.eks_cluster_name
  cluster_version = var.eks_kubernetes_version

  cluster_endpoint_private_access = var.cluster_endpoint_private_access
  cluster_endpoint_public_access  = var.cluster_endpoint_public_access

  vpc_id     = data.tfe_outputs.vpc.values.vpc_id
  subnet_ids = data.tfe_outputs.vpc.values.private_subnet_id

  eks_managed_node_group_defaults = {
    disk_size = var.worker_node_disk_size
  }

  eks_managed_node_groups = {
    general = {
      desired_size = var.worker_nodes_desired_size
      min_size     = var.worker_nodes_min_size
      max_size     = var.worker_nodes_max_size

      labels = {
        role = "general"
      }

      instance_types       = var.worker_node_instance_type_general
      ami_type             = var.ami_type
      capacity_type        = var.capacity_type
      force_update_version = var.force_update_version
    }

    spot = {
      desired_size = var.worker_nodes_desired_size
      min_size     = var.worker_nodes_min_size
      max_size     = var.worker_nodes_max_size

      labels = {
        role = "spot"
      }

      taints = [{
        key    = "market"
        value  = "spot"
        effect = "NO_SCHEDULE"
      }]

      instance_types       = var.worker_node_instance_type_spot
      ami_type             = var.ami_type
      capacity_type        = "SPOT"
      force_update_version = var.force_update_version
    }
  }

  // Enable OIDC IdP for Cluster
  cluster_identity_providers = {
    TF_Cloud = {
      client_id  = "aws.workload.identity"
      issuer_url = data.tls_certificate.tfc_certificate.url
    }
  }

  // Enable IRSA
  enable_irsa = true

  # aws-auth configmap
  manage_aws_auth_configmap = true
  create_aws_auth_configmap = var.create_aws_auth_configmap

  aws_auth_roles = [

    {
      rolearn  = module.eks_admins_iam_role.iam_role_arn
      username = "system:node:{{EC2PrivateDNSName}}"
      groups = [
        "system:bootstrappers",
        "system:nodes",
      ]
    },
    {
      rolearn  = module.iam_assumable_role_admin.iam_role_arn
      username = "system:node:{{EC2PrivateDNSName}}"
      groups = [
        "system:bootstrappers",
        "system:nodes",
      ]
    },
    {
      rolearn  = data.tfe_outputs.oidc.values.role_arn
      username = "system:node:{{EC2PrivateDNSName}}"
      groups = [
        "system:masters",
        "system:bootstrappers",
        "system:nodes",
      ]
    }
  ]

  # aws_auth_users = [
  #   {
  #     userarn  = 
  #     username = module.user1_iam_user.iam_user_name
  #     groups   = ["system:masters"]
  #   }
  # ]

  node_security_group_additional_rules = {
    ingress_allow_access_from_control_plane = {
      type                          = "ingress"
      protocol                      = "tcp"
      from_port                     = 9443
      to_port                       = 9443
      source_cluster_security_group = true
      description                   = "Allow access from control plane to webhook port of AWS load balancer controller"
    }
  }

  tags = var.eks_tags
}

# resource "null_resource" "kubectl" {
#   depends_on = [
#     module.eks
#   ]
#   provisioner "local-exec" {
#     command = "aws eks --region ${var.aws_region} update-kubeconfig --name ${var.eks_cluster_name}"
#   }
# }