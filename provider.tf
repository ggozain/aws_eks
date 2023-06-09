terraform {

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.61.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">=1.11.1"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.9.0"
    }
  }

  cloud {
    organization = "gozain-lab"
    workspaces {
      name = "aws_eks"
    }
  }

  required_version = ">= 0.12.9, != 0.13.0"
}

provider "aws" {
  region = var.aws_region
}

provider "aws" {
  region = "us-east-1"
  alias  = "virginia"
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.default.endpoint
  token                  = data.aws_eks_cluster_auth.default.token
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.default.certificate_authority[0].data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", var.eks_cluster_name]
  }
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.default.endpoint
    token                  = data.aws_eks_cluster_auth.default.token
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.default.certificate_authority[0].data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      # This requires the awscli to be installed locally where Terraform is executed
      args = ["eks", "get-token", "--cluster-name", var.eks_cluster_name]
    }
  }
}

provider "kubectl" {
  apply_retry_count      = 5
  host                   = data.aws_eks_cluster.default.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.default.certificate_authority[0].data)
  load_config_file       = false

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", var.eks_cluster_name]
  }
}