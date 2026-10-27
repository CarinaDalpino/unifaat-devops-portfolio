# -----------------------------------------------------------------------------
# DATA SOURCES
# -----------------------------------------------------------------------------

# AMI mais recente do Ubuntu 22.04 (usuário ssh "ubuntu", exigido pelo CD lab)
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Learner Lab já fornece LabRole e LabInstanceProfile (não é permitido criar IAM)
data "aws_iam_instance_profile" "lab_profile" {
  name = "LabInstanceProfile"
}

# -----------------------------------------------------------------------------
# KEY PAIR — gerado pelo Terraform (chave privada salva localmente p/ o secret SSH)
# -----------------------------------------------------------------------------

resource "tls_private_key" "deploy" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "deploy" {
  key_name   = "${var.project_name}-deploy-key"
  public_key = tls_private_key.deploy.public_key_openssh

  tags = {
    Name = "${var.project_name}-deploy-key"
  }
}

# Salva a chave privada localmente (vai para o secret EC2_SSH_KEY — NÃO commitar)
resource "local_file" "deploy_key" {
  content         = tls_private_key.deploy.private_key_pem
  filename        = "${path.module}/technova-deploy-key.pem"
  file_permission = "0600"
}

# -----------------------------------------------------------------------------
# ECR — repositório da imagem (destino do build+push do CD)
# -----------------------------------------------------------------------------

resource "aws_ecr_repository" "technova_api" {
  name                 = "technova-api"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.project_name}-api-ecr"
  }
}

# -----------------------------------------------------------------------------
# VPC + REDE
# -----------------------------------------------------------------------------

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet-${count.index + 1}"
    Type = "public"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# -----------------------------------------------------------------------------
# SECURITY GROUP — API (SSH + porta da API)
# -----------------------------------------------------------------------------

resource "aws_security_group" "api" {
  name        = "${var.project_name}-api-sg"
  description = "Security Group da API TechNova (CD deploy via SSH)"
  vpc_id      = aws_vpc.main.id

  # SSH — GitHub Actions runners usam IPs variáveis (0.0.0.0/0 no Lab)
  ingress {
    description = "SSH para GitHub Actions runners (CD pipeline)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  # API Node.js (health check e tráfego)
  ingress {
    description = "API Node.js"
    from_port   = var.api_port
    to_port     = var.api_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-api-sg"
  }
}

# -----------------------------------------------------------------------------
# EC2 — destino do deploy (Docker + AWS CLI instalados no boot)
# -----------------------------------------------------------------------------

resource "aws_instance" "api" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.api.id]
  iam_instance_profile   = data.aws_iam_instance_profile.lab_profile.name
  key_name               = aws_key_pair.deploy.key_name

  user_data = <<-EOF
    #!/bin/bash
    set -e
    apt-get update -y
    # Docker
    apt-get install -y docker.io
    systemctl enable docker
    systemctl start docker
    usermod -aG docker ubuntu
    # AWS CLI v2 (necessária para login no ECR)
    apt-get install -y unzip curl
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip -q awscliv2.zip
    ./aws/install
  EOF

  tags = {
    Name = "${var.project_name}-api-ec2"
  }
}
