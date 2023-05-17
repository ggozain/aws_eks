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

data "aws_eks_cluster" "default" {
  name = "Cluster-A"
}

data "aws_eks_cluster_auth" "default" {
  name = "Cluster-A"
}

data "aws_ecrpublic_authorization_token" "token" {
  provider = aws.virginia
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = ">= 19.13.1"

  cluster_name    = var.eks_cluster_name
  cluster_version = var.eks_kubernetes_version

  cluster_endpoint_private_access = var.cluster_endpoint_private_access
  cluster_endpoint_public_access  = var.cluster_endpoint_public_access

  vpc_id     = data.tfe_outputs.vpc.values.vpc_id
  subnet_ids = data.tfe_outputs.vpc.values.private_subnet_id
  # control_plane_subnet_ids = data.tfe_outputs.vpc.values.intra_subnet_id

  // Enable IRSA
  enable_irsa = true

  # cluster_addons = {
  #   kube-proxy = {}
  #   vpc-cni    = {}
  # coredns = {
  #   configuration_values = jsonencode({
  #     computeType = "Fargate"
  #     # Ensure that we fully utilize the minimum amount of resources that are supplied by
  #     # Fargate https://docs.aws.amazon.com/eks/latest/userguide/fargate-pod-configuration.html
  #     # Fargate adds 256 MB to each pod's memory reservation for the required Kubernetes
  #     # components (kubelet, kube-proxy, and containerd). Fargate rounds up to the following
  #     # compute configuration that most closely matches the sum of vCPU and memory requests in
  #     # order to ensure pods always have the resources that they need to run.
  #     resources = {
  #       limits = {
  #         cpu = "0.25"
  #         # We are targetting the smallest Task size of 512Mb, so we subtract 256Mb from the
  #         # request/limit to ensure we can fit within that task
  #         memory = "256M"
  #       }
  #       requests = {
  #         cpu = "0.25"
  #         # We are targetting the smallest Task size of 512Mb, so we subtract 256Mb from the
  #         # request/limit to ensure we can fit within that task
  #         memory = "256M"
  #       }
  #     }
  #   })
  # }
  # }

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



  # aws-auth configmap
  manage_aws_auth_configmap     = var.manage_aws_auth_configmap
  create_cluster_security_group = false
  create_node_security_group    = false
  create_aws_auth_configmap     = var.create_aws_auth_configmap

  aws_auth_roles = [

    # {
    #   rolearn  = module.karpenter.role_arn
    #   username = "system:node:{{EC2PrivateDNSName}}"
    #   groups = [
    #     "system:bootstrappers",
    #     "system:nodes",
    #   ]
    # },
    {
      rolearn  = module.eks_admins_iam_role.iam_role_arn
      username = module.eks_admins_iam_role.iam_role_name
      groups   = ["system:masters"]
    },

    {
      rolearn  = module.eks_admins_iam_role.iam_role_arn
      username = "system:node:{{EC2PrivateDNSName}}"
      groups = [
        "system:bootstrappers",
        "system:nodes",
      ]
    },
    {
      rolearn  = module.iam-assumable-role-with-oidc.iam_role_arn
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

  # fargate_profiles = {
  #   karpenter = {
  #     selectors = [
  #       { namespace = "karpenter" }
  #     ]
  #   }
  #   kube-system = {
  #     selectors = [
  #       { namespace = "kube-system" }
  #     ]
  #   }
  # }

  # node_security_group_additional_rules = {
  #   ingress_allow_access_from_control_plane = {
  #     type                          = "ingress"
  #     protocol                      = "tcp"
  #     from_port                     = 9443
  #     to_port                       = 9443
  #     source_cluster_security_group = true
  #     description                   = "Allow access from control plane to webhook port of AWS load balancer controller"
  #   }
  # }

  tags = var.eks_tags
}

################################ KARPENTER #######################################

# module "karpenter" {
#   source = "terraform-aws-modules/eks/aws//modules/karpenter"

#   cluster_name           = module.eks.cluster_name
#   irsa_oidc_provider_arn = module.eks.oidc_provider_arn

#   policies = {
#     AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
#   }

# }

# resource "helm_release" "karpenter" {
#   namespace        = "karpenter"
#   create_namespace = true

#   name                = "karpenter"
#   repository          = "oci://public.ecr.aws/karpenter"
#   repository_username = data.aws_ecrpublic_authorization_token.token.user_name
#   repository_password = data.aws_ecrpublic_authorization_token.token.password
#   chart               = "karpenter"
#   version             = "v0.21.1"

#   set {
#     name  = "settings.aws.clusterName"
#     value = module.eks.cluster_name
#   }

#   set {
#     name  = "settings.aws.clusterEndpoint"
#     value = module.eks.cluster_endpoint
#   }

#   set {
#     name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
#     value = module.karpenter.irsa_arn
#   }

#   set {
#     name  = "settings.aws.defaultInstanceProfile"
#     value = module.karpenter.instance_profile_name
#   }

#   set {
#     name  = "settings.aws.interruptionQueueName"
#     value = module.karpenter.queue_name
#   }
# }

# resource "kubectl_manifest" "karpenter_provisioner" {
#   yaml_body = <<-YAML
#     apiVersion: karpenter.sh/v1alpha5
#     kind: Provisioner
#     metadata:
#       name: default
#     spec:
#       requirements:
#         - key: karpenter.sh/capacity-type
#           operator: In
#           values: ["spot"]
#       limits:
#         resources:
#           cpu: 1000
#       providerRef:
#         name: default
#       ttlSecondsAfterEmpty: 30
#   YAML

#   depends_on = [
#     helm_release.karpenter
#   ]
# }

# resource "kubectl_manifest" "karpenter_node_template" {
#   yaml_body = <<-YAML
#     apiVersion: karpenter.k8s.aws/v1alpha1
#     kind: AWSNodeTemplate
#     metadata:
#       name: default
#     spec:
#       subnetSelector:
#         karpenter.sh/discovery: ${module.eks.cluster_name}
#       securityGroupSelector:
#         karpenter.sh/discovery: ${module.eks.cluster_name}
#       tags:
#         karpenter.sh/discovery: ${module.eks.cluster_name}
#   YAML

#   depends_on = [
#     helm_release.karpenter
#   ]
# }

# # Example deployment using the [pause image](https://www.ianlewis.org/en/almighty-pause-container)
# # and starts with zero replicas
# resource "kubectl_manifest" "karpenter_example_deployment" {
#   yaml_body = <<-YAML
#     apiVersion: apps/v1
#     kind: Deployment
#     metadata:
#       name: inflate
#     spec:
#       replicas: 0
#       selector:
#         matchLabels:
#           app: inflate
#       template:
#         metadata:
#           labels:
#             app: inflate
#         spec:
#           terminationGracePeriodSeconds: 0
#           containers:
#             - name: inflate
#               image: public.ecr.aws/eks-distro/kubernetes/pause:3.7
#               resources:
#                 requests:
#                   cpu: 1
#   YAML

#   depends_on = [
#     helm_release.karpenter
#   ]
# }



############# LOAD BALANCER #######################

# resource "helm_release" "aws_load_balancer_controller" {
#   name = "aws-load-balancer-controller"

#   repository = "https://aws.github.io/eks-charts"
#   chart      = "aws-load-balancer-controller"
#   namespace  = "kube-system"
#   version    = "1.4.4"

#   set {
#     name  = "replicaCount"
#     value = 1
#   }

#   set {
#     name  = "clusterName"
#     value = module.eks.cluster_id
#   }

#   set {
#     name  = "serviceAccount.name"
#     value = "aws-load-balancer-controller"
#   }

#   set {
#     name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
#     value = module.aws_load_balancer_controller_irsa_role.iam_role_arn
#   }
# }