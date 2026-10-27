variable "aws_region" {
  description = "Região AWS onde os recursos serão criados"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Ambiente de implantação"
  type        = string
  default     = "production"
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

# -----------------------------------------------------------------------------
# VPC
# -----------------------------------------------------------------------------
variable "vpc_cidr" {
  description = "CIDR block da VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDRs das subnets públicas"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.3.0/24"]
}

variable "availability_zones" {
  description = "Availability Zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

# -----------------------------------------------------------------------------
# EC2
# -----------------------------------------------------------------------------
variable "instance_type" {
  description = "Tipo da instância EC2 (t3.micro no Free Tier/Learner Lab)"
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
    CIDR permitido para SSH (porta 22).
    No Learner Lab, o deploy via GitHub Actions usa IPs variáveis dos runners,
    então liberamos 0.0.0.0/0. Em produção: restringir aos ranges do GitHub
    (https://api.github.com/meta) ou usar Bastion/VPN.
  EOT
  type        = string
  default     = "0.0.0.0/0"
}
