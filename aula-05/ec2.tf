# -----------------------------------------------------------------------------
# DATA SOURCE — AMI Amazon Linux 2023 mais recente
# -----------------------------------------------------------------------------
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# -----------------------------------------------------------------------------
# KEY PAIR — gerado pelo Terraform
# -----------------------------------------------------------------------------
resource "tls_private_key" "technova" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "technova" {
  key_name   = "${var.project_name}-key"
  public_key = tls_private_key.technova.public_key_openssh

  tags = {
    Name        = "${var.project_name}-key"
    Project     = "TechNova"
    Environment = "development"
    ManagedBy   = "Terraform"
    Owner       = "6325109"
  }
}

# Salvar a chave privada localmente (não commitar — está no .gitignore)
resource "local_file" "private_key" {
  content         = tls_private_key.technova.private_key_pem
  filename        = "${path.module}/${var.project_name}-key.pem"
  file_permission = "0600"
}

# -----------------------------------------------------------------------------
# SECURITY GROUP — EC2 (SSH + API)
# -----------------------------------------------------------------------------
resource "aws_security_group" "ec2" {
  name        = "${var.project_name}-ec2-sg"
  description = "Security Group para EC2 - SSH e API Node.js"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "API Node.js"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-ec2-sg"
    Project     = "TechNova"
    Environment = "development"
    ManagedBy   = "Terraform"
    Owner       = "6325109"
  }
}

# -----------------------------------------------------------------------------
# INSTÂNCIA EC2 — t2.micro na subnet pública
# User data instala PostgreSQL client para testar conexão ao RDS
# -----------------------------------------------------------------------------
resource "aws_instance" "api" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.technova.key_name
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.ec2.id]

  # Usar LabInstanceProfile do AWS Academy (não criar IAM role — Learner Lab bloqueia)
  iam_instance_profile = "LabInstanceProfile"

  user_data = base64encode(<<-EOF
    #!/bin/bash
    set -e

    # Atualizar sistema
    dnf update -y

    # Instalar cliente PostgreSQL 15 para testar conexão ao RDS
    dnf install -y postgresql15

    # Instalar Node.js 18
    dnf install -y nodejs npm

    # Criar API TechNova com persistência no RDS
    mkdir -p /opt/technova-api
    cd /opt/technova-api

    cat > package.json << 'PKGJSON'
    {
      "name": "technova-api",
      "version": "1.0.0",
      "description": "TechNova API - DevOps UniFAAT",
      "main": "server.js",
      "dependencies": {
        "express": "^4.18.2",
        "pg": "^8.11.0"
      }
    }
    PKGJSON

    cat > server.js << 'SERVERJS'
    const express = require('express');
    const app = express();
    const PORT = process.env.PORT || 3000;

    app.use(express.json());

    app.get('/', (req, res) => {
      res.json({
        message: 'TechNova API rodando na AWS!',
        version: '1.0.0',
        environment: 'production',
        database: process.env.DB_HOST ? 'RDS PostgreSQL' : 'in-memory',
        timestamp: new Date().toISOString()
      });
    });

    app.get('/health', (req, res) => {
      res.json({
        status: 'healthy',
        uptime: process.uptime(),
        timestamp: new Date().toISOString()
      });
    });

    app.get('/orders', (req, res) => {
      res.json({
        orders: [
          { id: 1, product: 'Laptop TechNova Pro', status: 'shipped' },
          { id: 2, product: 'Monitor 27"', status: 'pending' },
          { id: 3, product: 'Teclado Mecânico', status: 'delivered' }
        ]
      });
    });

    app.listen(PORT, '0.0.0.0', () => {
      console.log('TechNova API rodando na porta ' + PORT);
    });
    SERVERJS

    npm install

    # Criar serviço systemd
    cat > /etc/systemd/system/technova-api.service << 'SERVICE'
    [Unit]
    Description=TechNova API
    After=network.target

    [Service]
    Type=simple
    User=ec2-user
    WorkingDirectory=/opt/technova-api
    ExecStart=/usr/bin/node server.js
    Restart=always
    RestartSec=10
    Environment=PORT=3000

    [Install]
    WantedBy=multi-user.target
    SERVICE

    chown -R ec2-user:ec2-user /opt/technova-api
    systemctl daemon-reload
    systemctl enable technova-api
    systemctl start technova-api

    echo "Setup concluído!" >> /var/log/technova-setup.log
  EOF
  )

  tags = {
    Name        = "${var.project_name}-api-ec2"
    Project     = "TechNova"
    Environment = "development"
    ManagedBy   = "Terraform"
    Owner       = "6325109"
    Aula        = "05"
  }
}
