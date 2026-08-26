# -----------------------------------------------------------------------------
# KEY PAIR — gerado pelo Terraform (chave privada salva localmente)
# -----------------------------------------------------------------------------

resource "tls_private_key" "technova" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "technova" {
  key_name   = "${var.project_name}-key"
  public_key = tls_private_key.technova.public_key_openssh

  tags = {
    Name = "${var.project_name}-key"
  }
}

# Salva a chave privada localmente (não commitar!)
resource "local_file" "private_key" {
  content         = tls_private_key.technova.private_key_pem
  filename        = "${path.module}/${var.project_name}-key.pem"
  file_permission = "0600"
}

# -----------------------------------------------------------------------------
# IAM ROLE — Instance Profile para EC2
# -----------------------------------------------------------------------------

resource "aws_iam_role" "ec2_role" {
  name        = "${var.project_name}-ec2-role"
  description = "Role IAM para instância EC2 TechNova"

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

  tags = {
    Name = "${var.project_name}-ec2-role"
  }
}

# Attach da policy S3 Read Only (Free Tier, sem custos extras)
resource "aws_iam_role_policy_attachment" "s3_read" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-ec2-profile"
  role = aws_iam_role.ec2_role.name

  tags = {
    Name = "${var.project_name}-ec2-profile"
  }
}

# -----------------------------------------------------------------------------
# EC2 INSTANCE — API TechNova
# -----------------------------------------------------------------------------

resource "aws_instance" "api" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.api.id]
  key_name               = aws_key_pair.technova.key_name
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  user_data = base64encode(<<-EOF
    #!/bin/bash
    set -e

    # Atualiza o sistema
    dnf update -y

    # Instala Node.js 18
    dnf install -y nodejs npm

    # Instala Git
    dnf install -y git

    # Cria diretório da aplicação
    mkdir -p /opt/technova-api
    cd /opt/technova-api

    # Cria a API TechNova simplificada
    cat > package.json << 'PKGJSON'
    {
      "name": "technova-api",
      "version": "1.0.0",
      "description": "TechNova API - DevOps UniFAAT",
      "main": "server.js",
      "scripts": {
        "start": "node server.js"
      },
      "dependencies": {
        "express": "^4.18.2"
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
          { id: 1, product: 'Produto A', status: 'pending' },
          { id: 2, product: 'Produto B', status: 'shipped' }
        ]
      });
    });

    app.listen(PORT, '0.0.0.0', () => {
      console.log('TechNova API rodando na porta ' + PORT);
    });
    SERVERJS

    # Instala dependências
    npm install

    # Cria serviço systemd para iniciar automaticamente
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

    # Ajusta permissões
    chown -R ec2-user:ec2-user /opt/technova-api

    # Habilita e inicia o serviço
    systemctl daemon-reload
    systemctl enable technova-api
    systemctl start technova-api
  EOF
  )

  tags = {
    Name = "${var.project_name}-api-ec2"
  }
}
