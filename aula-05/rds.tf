# -----------------------------------------------------------------------------
# DB SUBNET GROUP — obrigatório, precisa de subnets em 2 AZs diferentes
# -----------------------------------------------------------------------------
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = [aws_subnet.private_1.id, aws_subnet.private_2.id]

  tags = {
    Name        = "${var.project_name}-db-subnet-group"
    Project     = "TechNova"
    Environment = "development"
    ManagedBy   = "Terraform"
    Owner       = "6325109"
    Aula        = "05"
  }
}

# -----------------------------------------------------------------------------
# SECURITY GROUP — RDS (porta 5432 apenas da VPC)
# -----------------------------------------------------------------------------
resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg"
  description = "Security Group para RDS - permite PostgreSQL apenas do EC2"
  vpc_id      = aws_vpc.main.id

  # Melhor prática: referenciar o SG do EC2 em vez de abrir para o CIDR da VPC
  ingress {
    description     = "PostgreSQL from EC2 only"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2.id]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-rds-sg"
    Project     = "TechNova"
    Environment = "development"
    ManagedBy   = "Terraform"
    Owner       = "6325109"
    Aula        = "05"
  }
}

# -----------------------------------------------------------------------------
# INSTÂNCIA RDS POSTGRESQL — Free Tier (db.t3.micro)
# Leva 5-10 minutos para provisionar — isso é normal
# -----------------------------------------------------------------------------
resource "aws_db_instance" "main" {
  identifier = "${var.project_name}-db"

  # Engine
  engine         = "postgres"
  engine_version = "15"

  # Capacidade — Free Tier
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  storage_type      = "gp2"

  # Banco de dados
  db_name  = var.db_name
  username = var.db_username
  password = var.db_password
  port     = 5432

  # Rede — subnet privada, sem acesso público
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false

  # Alta disponibilidade — desligada (não é Free Tier)
  multi_az = false

  # Backup automático
  backup_retention_period = 7
  backup_window           = "03:00-04:00"

  # Janela de manutenção
  maintenance_window = "sun:04:00-sun:05:00"

  # Segurança
  storage_encrypted = true

  # Para lab: não criar snapshot ao destruir (em produção, sempre tire snapshot!)
  skip_final_snapshot = true

  # Performance Insights — desligado (não é Free Tier)
  performance_insights_enabled = false

  tags = {
    Name        = "${var.project_name}-rds"
    Project     = "TechNova"
    Environment = "development"
    ManagedBy   = "Terraform"
    Owner       = "6325109"
    Aula        = "05"
  }
}
