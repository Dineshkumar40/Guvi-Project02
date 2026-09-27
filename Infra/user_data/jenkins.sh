#!/bin/bash

set -e

# ==========================================
# System update
# ==========================================

apt-get update -y

# ==========================================
# Basic packages
# ==========================================

apt-get install -y \
  wget \
  curl \
  unzip \
  git \
  ca-certificates \
  gnupg \
  apt-transport-https \
  software-properties-common

# ==========================================
# Java 21
# ==========================================

apt-get install -y openjdk-21-jre

java -version

# ==========================================
# Docker
# ==========================================

install -m 0755 -d /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  -o /etc/apt/keyrings/docker.asc

chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
  > /etc/apt/sources.list.d/docker.list

apt-get update -y

apt-get install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin

systemctl enable docker
systemctl start docker

# ==========================================
# Jenkins
# ==========================================

curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key \
  -o /usr/share/keyrings/jenkins-keyring.asc

echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ \
  > /etc/apt/sources.list.d/jenkins.list

apt-get update -y

apt-get install -y jenkins

# ==========================================
# Docker permissions
# ==========================================

# Allow Ubuntu user to use Docker
usermod -aG docker ubuntu

# Allow Jenkins to use Docker
usermod -aG docker jenkins

# ==========================================
# Start Jenkins
# ==========================================

systemctl enable jenkins
systemctl restart jenkins

# ==========================================
# AWS CLI v2
# ==========================================

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" \
  -o "/tmp/awscliv2.zip"

unzip -q /tmp/awscliv2.zip -d /tmp

/tmp/aws/install

aws --version

# ==========================================
# kubectl
# ==========================================

curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

install \
  -o root \
  -g root \
  -m 0755 \
  kubectl \
  /usr/local/bin/kubectl

kubectl version --client

# ==========================================
# Cleanup
# ==========================================

rm -f kubectl
rm -f /tmp/awscliv2.zip

# ==========================================
# Final Jenkins restart
# ==========================================

systemctl restart jenkins

echo "======================================"
echo " Jenkins installation completed"
echo " Docker permissions configured"
echo "======================================"