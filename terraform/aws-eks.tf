### AWS EKS Configurations ###

# EKS Cluster Definition
resource "aws_eks_cluster" "k8s-cluster" {
  name     = "k8s-cluster-devtest"
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids              = concat(aws_subnet.k8s_private_subnet.*.id, aws_subnet.k8s_public_subnet.*.id)
    endpoint_private_access = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.k8sClusterPolicyAttachment
  ]
}


# EKS Node Group Definition
resource "aws_eks_node_group" "k8s_ng-public" {
  cluster_name    = aws_eks_cluster.k8s-cluster.name
  node_group_name = "k8s-ng-devtest-public"
  node_role_arn   = aws_iam_role.eks_nodegroup_role.arn
  subnet_ids      = concat(aws_subnet.k8s_public_subnet.*.id)

  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }

  instance_types  = [var.eks_ng_type]

  depends_on = [
    aws_iam_role_policy_attachment.k8sWorkerNodePolicyAttachment,
    aws_iam_role_policy_attachment.k8sCNIPolicyAttachment,
    aws_iam_role_policy_attachment.k8sEC2ContainerRegistryReadOnly
  ]
}

resource "aws_eks_node_group" "k8s_ng_private" {
  cluster_name    = aws_eks_cluster.k8s-cluster.name
  node_group_name = "k8s-ng-devtest-private"
  node_role_arn   = aws_iam_role.eks_nodegroup_role.arn
  subnet_ids      = concat(aws_subnet.k8s_private_subnet.*.id)

  scaling_config {
    desired_size = 2
    max_size     = 2
    min_size     = 1
  }

  instance_types  = [var.eks_ng_type]

  depends_on = [
    aws_iam_role_policy_attachment.k8sWorkerNodePolicyAttachment,
    aws_iam_role_policy_attachment.k8sCNIPolicyAttachment,
    aws_iam_role_policy_attachment.k8sEC2ContainerRegistryReadOnly
  ]
}

# # EKS Fargate Profile Definition
# resource "aws_eks_fargate_profile" "k8s_fargate" {
#   cluster_name           = aws_eks_cluster.k8s-cluster.name
#   fargate_profile_name   = "k8s-fg-devtest-profile"
#   pod_execution_role_arn = aws_iam_role.eks_fargate_role.arn
#   subnet_ids             = aws_subnet.k8s_private_subnet.*.id

#   selector {
#     namespace = "fargate"
#   }

# }