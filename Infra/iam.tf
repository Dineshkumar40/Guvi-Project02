# ============================================================
# iam.tf
# Trend Application - IAM Configuration
# ============================================================


# ============================================================
# 1. JENKINS IAM ROLE
# ============================================================
# This role is attached to the Jenkins EC2 instance.
#
# Jenkins uses this role to:
#   - Authenticate with AWS
#   - Get EKS cluster information
#   - Generate kubeconfig for EKS
#
# DockerHub authentication is NOT handled by IAM.
# DockerHub credentials will be stored in Jenkins Credentials.
# ============================================================

resource "aws_iam_role" "jenkins" {

  name = "${local.name}-jenkins-role"

  assume_role_policy = jsonencode({

    Version = "2012-10-17"

    Statement = [

      {
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }

    ]
  })

  tags = local.common_tags
}


# ============================================================
# 2. JENKINS EKS DEPLOYMENT POLICY
# ============================================================
# Jenkins needs this permission to obtain information about
# the EKS cluster.
#
# This is used by:
#
# aws eks update-kubeconfig
#
# Kubernetes permissions are handled separately through
# EKS Access Entry / Kubernetes authorization.
# ============================================================

resource "aws_iam_policy" "jenkins_eks_deploy" {

  name = "${local.name}-jenkins-eks-deploy"

  description = "Minimal AWS permissions for Jenkins to deploy to EKS"

  policy = jsonencode({

    Version = "2012-10-17"

    Statement = [

      {
        Effect = "Allow"

        Action = [
          "eks:DescribeCluster"
        ]

        Resource = aws_eks_cluster.main.arn
      }

    ]
  })

  tags = local.common_tags
}


# ============================================================
# 3. ATTACH JENKINS EKS POLICY
# ============================================================

resource "aws_iam_role_policy_attachment" "jenkins_eks_deploy" {

  role = aws_iam_role.jenkins.name

  policy_arn = aws_iam_policy.jenkins_eks_deploy.arn
}


# ============================================================
# 4. JENKINS INSTANCE PROFILE
# ============================================================
# EC2 cannot directly attach an IAM role.
#
# EC2 uses:
#
# IAM Role
#    ↓
# Instance Profile
#    ↓
# EC2
#
# Your Jenkins EC2 instance will use this instance profile.
# ============================================================

resource "aws_iam_instance_profile" "jenkins" {

  name = "${local.name}-jenkins-profile"

  role = aws_iam_role.jenkins.name

  tags = local.common_tags
}


# ============================================================
# 5. EKS CLUSTER IAM ROLE
# ============================================================
# This role is assumed by the EKS service itself.
#
# EKS control plane
#       ↓
# eks-cluster-role
# ============================================================

resource "aws_iam_role" "eks_cluster" {

  name = "${local.name}-eks-cluster-role"

  assume_role_policy = jsonencode({

    Version = "2012-10-17"

    Statement = [

      {
        Effect = "Allow"

        Principal = {
          Service = "eks.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }

    ]
  })

  tags = local.common_tags
}


# ============================================================
# 6. EKS CLUSTER POLICY
# ============================================================

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {

  role = aws_iam_role.eks_cluster.name

  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}


# ============================================================
# 7. EKS VPC RESOURCE CONTROLLER POLICY
# ============================================================
# Allows EKS to manage required VPC resources.
# ============================================================

resource "aws_iam_role_policy_attachment" "eks_vpc_resource_controller" {

  role = aws_iam_role.eks_cluster.name

  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}


# ============================================================
# 8. EKS NODE IAM ROLE
# ============================================================
# This role is attached to EC2 worker nodes.
#
# Worker Node EC2
#       ↓
# eks-node-role
# ============================================================

resource "aws_iam_role" "eks_nodes" {

  name = "${local.name}-eks-node-role"

  assume_role_policy = jsonencode({

    Version = "2012-10-17"

    Statement = [

      {
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }

    ]
  })

  tags = local.common_tags
}


# ============================================================
# 9. EKS WORKER NODE POLICY
# ============================================================
# Allows worker nodes to communicate with the EKS control plane
# and operate as Kubernetes worker nodes.
# ============================================================

resource "aws_iam_role_policy_attachment" "eks_worker_node" {

  role = aws_iam_role.eks_nodes.name

  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}


# ============================================================
# 10. EKS CNI POLICY
# ============================================================
# Allows the AWS VPC CNI plugin to manage networking for pods.
# ============================================================

resource "aws_iam_role_policy_attachment" "eks_cni" {

  role = aws_iam_role.eks_nodes.name

  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}


# ============================================================
# 11. ECR READ-ONLY POLICY
# ============================================================
# OPTIONAL for your current project.
#
# Your application image will be stored in DockerHub, not ECR.
#
# We can remove this if you want a strictly minimal setup.
# Keeping it does not affect DockerHub deployment.
# ============================================================

resource "aws_iam_role_policy_attachment" "eks_ecr" {

  role = aws_iam_role.eks_nodes.name

  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}


# ============================================================
# 12. EKS NODE INSTANCE PROFILE
# ============================================================
# Managed node groups normally handle the instance profile
# through the EKS node group configuration.
#
# If your aws_eks_node_group uses node_role = aws_iam_role.eks_nodes.arn,
# you DO NOT need to manually attach this instance profile there.
#
# Therefore no separate aws_iam_instance_profile resource is required
# for the managed node group.
# ============================================================


# ============================================================
# 13. EKS ACCESS ENTRY FOR JENKINS
# ============================================================
# This connects the Jenkins IAM identity to the EKS cluster.
#
# IAM:
#
# Jenkins IAM Role
#       ↓
# EKS Access Entry
#
# After this, we associate an EKS access policy below.
# ============================================================

resource "aws_eks_access_entry" "jenkins" {

  cluster_name = aws_eks_cluster.main.name

  principal_arn = aws_iam_role.jenkins.arn

  type = "STANDARD"

  depends_on = [
    aws_eks_cluster.main
  ]
}


# ============================================================
# 14. EKS ACCESS POLICY FOR JENKINS
# ============================================================
# This gives Jenkins Kubernetes permissions through EKS.
#
# For this project, Jenkins needs to deploy:
#
#   Deployment
#   Service
#
# We use the EKS managed policy below.
#
# Note:
# The exact policy scope can be further restricted later using
# Kubernetes RBAC if required.
# ============================================================

resource "aws_eks_access_policy_association" "jenkins" {

  cluster_name = aws_eks_cluster.main.name

  principal_arn = aws_iam_role.jenkins.arn

  policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSEditPolicy"

  access_scope {

    type = "cluster"
  }

  depends_on = [
    aws_eks_access_entry.jenkins
  ]
}