// AWS Region
aws_region  = "eu-west-2"
environment = "test"

// TF cloud details where the VPC module was applied from
tfcloud_organization   = "gozain-lab"
tfcloud_workspace_vpc  = "aws_vpc"
tfcloud_workspace_oidc = "aws_oidc_provider"


//EKS configuration
eks_kubernetes_version          = "1.26"
eks_cluster_iam_role_name       = "Cluster-A" //MUST match the k8s labels created for the subnets in vpc/module (i.e. "kubernetes.io/cluster/eks" where <eks> is the cluster name)
nodes_general_iam_role_name     = "nodes_general"
eks_cluster_name                = "Cluster-A"
node_group_name                 = "node-group-1"
create_aws_auth_configmap       = false
manage_aws_auth_configmap       = true
cluster_endpoint_private_access = true
cluster_endpoint_public_access  = true

//  // scaling variables
# Desired number of worker nodes.
worker_nodes_desired_size = 1
# Maximum number of worker nodes.
worker_nodes_max_size = 10
# Minimum number of worker nodes.
worker_nodes_min_size = 1
# Worked nodes disk size in GiB
worker_node_disk_size = 20


// // Type of Amazon Machine Image (AMI) associated with the EKS Node Group.
# Valid values: AL2_x86_64, AL2_x86_64_GPU, AL2_ARM_64
ami_type = "AL2_x86_64"

# Force version update if existing pods are unable to be drained due to a pod disruption budget issue.
# boolean (true/false)
force_update_version = false

# Type of capacity associated with the EKS Node Group under General.  
# Valid values: ON_DEMAND, SPOT
capacity_type = "ON_DEMAND"

# List of instance types associated with the EKS Node Group
//GENERAL
worker_node_instance_type_general = ["t3.small"]
//SPOT
worker_node_instance_type_spot = ["t3.micro"]

// Tags
eks_tags = {
  Environment = "test"
}