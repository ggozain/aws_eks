data "tfe_outputs" "vpc" {
  organization = var.tfcloud_organization
  workspace    = var.tfcloud_workspace_vpc
}


module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "18.29.0"

  cluster_name    = var.eks_cluster_name
  cluster_version = var.eks_kubernetes_version

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  vpc_id     = data.tfe_outputs.vpc.values.vpc_id
  subnet_ids = data.tfe_outputs.vpc.values.private_subnet_id

  enable_irsa = true

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
  manage_aws_auth_configmap = true
  aws_auth_roles = [
    {
      rolearn  = module.eks_admins_iam_role.iam_role_arn
      username = module.eks_admins_iam_role.iam_role_name
      groups   = ["system:masters"]
    },
  ]

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

resource "null_resource" "kubectl" {
  provisioner "local-exec" {
    command = "aws eks --region ${var.aws_region} update-kubeconfig --name ${var.eks_cluster_name}"
  }
}