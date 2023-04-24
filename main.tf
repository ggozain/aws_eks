data "tfe_outputs" "vpc" {
  organization = var.tfcloud_organization
  workspace    = var.tfcloud_workspace
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

  tags = {
    Environment = "staging"
  }
}