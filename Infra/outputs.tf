output "vpc_id" {
  description = "VPC ID"

  value = aws_vpc.main.id
}

output "public_subnet_1_id" {
  description = "Public subnet 1"

  value = aws_subnet.public_1.id
}

output "public_subnet_2_id" {
  description = "Public subnet 2"

  value = aws_subnet.public_2.id
}

output "jenkins_instance_id" {
  description = "Jenkins EC2 instance ID"

  value = aws_instance.jenkins.id
}

output "jenkins_public_ip" {
  description = "Jenkins public IP"

  value = aws_instance.jenkins.public_ip
}

output "jenkins_public_dns" {
  description = "Jenkins public DNS"

  value = aws_instance.jenkins.public_dns
}

output "jenkins_url" {
  description = "Jenkins URL"

  value = "http://${aws_instance.jenkins.public_ip}:8080"
}

output "eks_cluster_name" {
  description = "EKS cluster name"

  value = aws_eks_cluster.main.name
}

output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"

  value = aws_eks_cluster.main.endpoint
}

output "eks_cluster_arn" {
  description = "EKS cluster ARN"

  value = aws_eks_cluster.main.arn
}

output "eks_node_group_name" {
  description = "EKS node group name"

  value = aws_eks_node_group.main.node_group_name
}

output "aws_region" {
  description = "AWS region"

  value = var.aws_region
}