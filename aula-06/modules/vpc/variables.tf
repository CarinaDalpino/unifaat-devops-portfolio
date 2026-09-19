# modules/vpc/variables.tf

variable "vpc_cidr" {
  description = "CIDR block principal da VPC"
  type        = string
}

variable "project_name" {
  description = "Nome do projeto para tags"
  type        = string
}

variable "environment" {
  description = "Ambiente (dev, staging, prod)"
  type        = string
}

variable "subnets" {
  description = "Mapa de subnets a serem criadas (cidr, az, type)"
  type = map(object({
    cidr = string
    az   = string
    type = string # "public" ou "private"
  }))
}