# ==========================================
# Ubuntu 24.04 AMI
# ==========================================

data "aws_ssm_parameter" "ubuntu_ami" {
  name = "/aws/service/canonical/ubuntu/server/24.04/stable/current/amd64/hvm/ebs-gp3/ami-id"
}

# ==========================================
# Jenkins EC2
# ==========================================

resource "aws_instance" "jenkins" {
  ami = data.aws_ssm_parameter.ubuntu_ami.value

  instance_type = var.jenkins_instance_type

  subnet_id = aws_subnet.public_1.id

  vpc_security_group_ids = [
    aws_security_group.jenkins.id
  ]

  iam_instance_profile = aws_iam_instance_profile.jenkins.name

  key_name = var.key_name

  associate_public_ip_address = true

  user_data = file("${path.module}/user_data/jenkins.sh")

  root_block_device {
    volume_size = 30

    volume_type = "gp3"

    encrypted = true
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name}-jenkins"
    }
  )

  depends_on = [
    aws_internet_gateway.main
  ]
}