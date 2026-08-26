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
  description = "Tipo da instância EC2 (Free Tier)"
  type        = string
  default     = "t2.micro"
}

variable "api_port" {
  description = "Porta da API Node.js"
  type        = number
  default     = 3000
}
