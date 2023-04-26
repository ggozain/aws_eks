variable "aws_region" {
  type = string
}

variable "tfcloud_organization" {
  type = string
}

variable "tfcloud_workspace_vpc" {
  type = string
}

variable "tfcloud_workspace_oidc" {
  type = string
}

variable "tfc_hostname" {
  type        = string
  default     = "app.terraform.io"
  description = "The hostname of the TFC or TFE instance you'd like to use with AWS"
}

variable "eks_kubernetes_version" {
  type        = string
  description = "the desired kubernetes version to be used when creating EKS cluster"
}

variable "cluster_endpoint_private_access" {
  type        = bool
  description = "Enable Cluster private access"
  default     = false
}

variable "cluster_endpoint_public_access" {
  type        = bool
  description = "Enable Cluster private access"
  default     = false
}

variable "eks_cluster_iam_role_name" {
  type        = string
  description = "the desired name for the eks_iam_role"
}

variable "nodes_general_iam_role_name" {
  type        = string
  description = "the desired name for the iam_nodes_general_role_name"
}

variable "eks_cluster_name" {
  type        = string
  description = "the desired name for the eks cluster"
}

variable "node_group_name" {
  type        = string
  description = "the desired name for the node group name"
}

variable "node_group_private_subnet_ids" {
  type        = list(any)
  description = "a list containing the ids for the private subnets create by vpc module"
  default     = []
}

variable "worker_nodes_desired_size" {
  type        = number
  description = "desired number of worker nodes on cluster"
}

variable "worker_nodes_max_size" {
  type        = number
  description = "maximum number of worker nodes on cluster"
}

variable "worker_nodes_min_size" {
  type        = number
  description = "minimum number of worker nodes on cluster"
}

variable "worker_node_disk_size" {
  type        = number
  description = "worker node disx size in GiB"
  default     = 20
}

variable "worker_node_instance_type_general" {
  type        = list(any)
  description = "General worker node EC2 instance type"
  default     = ["t3.small"]
}

variable "worker_node_instance_type_spot" {
  type        = list(any)
  description = "Spot worker node EC2 instance type"
  default     = ["t3.small"]
}

variable "ami_type" {
  type        = string
  description = "worker node EC2 ami type"
}

variable "capacity_type" {
  type        = string
  description = "worker node EC2 capacity type"
}

variable "force_update_version" {
  type        = bool
  description = "worker node EC2 force update option"
}

variable "environment" {
  type        = string
  description = "Environment that EKS is being deployed on to for tagging purposes"
}

variable "eks_tags" {
  type        = map(any)
  description = "EKS node tags"
}

variable "create_aws_auth_configmap" {
  type        = bool
  description = "Create Kube aws config map aws_auth"
  default     = false

}