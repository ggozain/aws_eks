terraform {

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.61.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.6.0"
    }
  }

  cloud {
    organization = "gozain-lab"
    workspaces {
      name = "aws_eks"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = var.aws_region
}
