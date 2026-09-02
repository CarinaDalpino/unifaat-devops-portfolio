variable "aws_region" {
  description = "Região AWS onde os recursos serão criados"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Ambiente de implantação"
  type        = string
  default     = "development"
}

variable "owner_ra" {
  description = "RA do aluno responsável"
  type        = string
  default     = "6325109"
}

variable "project_name" {
  description = "Nome do projeto"
  type        = string
  default     = "technova"
}

# VPC
variable "vpc_cidr" {
  description = "CIDR block da VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# Subnets públicas em 2 AZs diferentes
variable "public_subnet_cidrs" {
  description = "CIDRs das subnets públicas"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.3.0/24"]
}

# Subnets privadas em 2 AZs diferentes
variable "private_subnet_cidrs" {
  description = "CIDRs das subnets privadas"
  type        = list(string)
  default     = ["10.0.2.0/24", "10.0.4.0/24"]
}

variable "availability_zones" {
  description = "Availability Zones para distribuição Multi-AZ"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

# EC2
variable "instance_type" {
  description = <<-EOT
    Tipo da instância EC2.
    Nota: O requisito original especifica t2.micro (Free Tier clássico).
    Usamos t3.micro (Free Tier novo) pois na região us-east-1 o t2.micro
    não estava disponível como Free Tier nesta conta AWS.
    Ambos estão no Free Tier, mas t3.micro é a geração mais recente e
    oferece melhor performance com o mesmo custo zero.
    Validar elegibilidade Free Tier em: https://aws.amazon.com/free/
  EOT
  type        = string
  default     = "t3.micro"
}

variable "api_port" {
  description = "Porta da API Node.js"
  type        = number
  default     = 3000
}

variable "allowed_ssh_cidr" {
  description = <<-EOT
    CIDR permitido para acesso SSH (porta 22).
    DEV: 0.0.0.0/0 (qualquer IP — apenas para laboratório)
    PROD: usar IP específico do administrador, ex: "203.0.113.10/32"
    RECOMENDAÇÃO: Em produção, substituir por Bastion Host ou VPN
    e remover acesso SSH direto ao EC2.
  EOT
  type        = string
  default     = "0.0.0.0/0"
}
