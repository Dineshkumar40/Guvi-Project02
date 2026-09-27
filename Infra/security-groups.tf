# ==========================================
# Jenkins Security Group
# ==========================================

resource "aws_security_group" "jenkins" {
  name = "${local.name}-jenkins-sg"

  description = "Security group for Jenkins"

  vpc_id = aws_vpc.main.id

  # SSH
  ingress {
    description = "SSH"

    from_port = 22
    to_port   = 22

    protocol = "tcp"

    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  # Jenkins
  ingress {
    description = "Jenkins"

    from_port = 8080
    to_port   = 8080

    protocol = "tcp"

    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  # Outbound
  egress {
    description = "Allow all outbound traffic"

    from_port = 0
    to_port   = 0

    protocol = "-1"

    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name}-jenkins-sg"
    }
  )
}

# ==========================================
# EKS Cluster Security Group
# ==========================================

resource "aws_security_group" "eks_cluster" {
  name = "${local.name}-eks-cluster-sg"

  description = "Security group for EKS control plane"

  vpc_id = aws_vpc.main.id

  # Jenkins -> EKS API
  ingress {
    description = "Jenkins access to EKS API"

    from_port = 443
    to_port   = 443

    protocol = "tcp"

    security_groups = [
      aws_security_group.jenkins.id
    ]
  }

  egress {
    description = "Allow outbound traffic"

    from_port = 0
    to_port   = 0

    protocol = "-1"

    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name}-eks-cluster-sg"
    }
  )
}

# ==========================================
# EKS Node Security Group
# ==========================================

resource "aws_security_group" "eks_nodes" {
  name = "${local.name}-eks-nodes-sg"

  description = "Security group for EKS worker nodes"

  vpc_id = aws_vpc.main.id

  # Node-to-node communication
  ingress {
    description = "Node to node communication"

    from_port = 0
    to_port   = 65535

    protocol = "tcp"

    self = true
  }

  # EKS cluster to node
  ingress {
    description = "EKS cluster to worker nodes"

    from_port = 443
    to_port   = 443

    protocol = "tcp"

    security_groups = [
      aws_security_group.eks_cluster.id
    ]
  }

  # Kubelet
  ingress {
    description = "Kubelet"

    from_port = 10250
    to_port   = 10250

    protocol = "tcp"

    security_groups = [
      aws_security_group.eks_cluster.id
    ]
  }

  # HTTP
  ingress {
    description = "HTTP"

    from_port = 80
    to_port   = 80

    protocol = "tcp"

    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  # HTTPS
  ingress {
    description = "HTTPS"

    from_port = 443
    to_port   = 443

    protocol = "tcp"

    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  # Outbound
  egress {
    description = "Allow all outbound traffic"

    from_port = 0
    to_port   = 0

    protocol = "-1"

    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name}-eks-nodes-sg"

      "kubernetes.io/cluster/${local.name}-eks" = "owned"
    }
  )
}