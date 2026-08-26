# -----------------------------------------------------------------------------
# SECURITY GROUP — API (EC2)
# -----------------------------------------------------------------------------

resource "aws_security_group" "api" {
  name        = "${var.project_name}-api-sg"
  description = "Security Group da API TechNova"
  vpc_id      = aws_vpc.main.id

  # SSH
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # API Node.js
  ingress {
    description = "API Node.js"
    from_port   = var.api_port
    to_port     = var.api_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Todo tráfego de saída permitido
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
# SECURITY GROUP — BANCO DE DADOS (futuro uso com RDS)
# -----------------------------------------------------------------------------

resource "aws_security_group" "db" {
  name        = "${var.project_name}-db-sg"
  description = "Security Group do banco de dados TechNova"
  vpc_id      = aws_vpc.main.id

  # PostgreSQL — apenas tráfego interno da VPC (menor privilégio)
  ingress {
    description = "PostgreSQL from VPC only"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Todo tráfego de saída permitido
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-db-sg"
  }
}
