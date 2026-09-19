# modules/rds/variables.tf

variable "db_name" {
  description = "Nome do database"
  type        = string
}

variable "db_username" {
  description = "Usuario master do banco"
  type        = string
}

variable "db_password" {
  description = "Senha master do banco"
  type        = string
  sensitive   = true
}

variable "subnet_ids" {
  description = "Subnet IDs para o DB Subnet Group (subnets privadas)"
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security Group IDs para o RDS"
  type        = list(string)
}

variable "instance_class" {
  description = "Classe da instancia RDS"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Armazenamento alocado em GB"
  type        = number
  default     = 20
}

variable "engine_version" {
  description = "Versao do PostgreSQL"
  type        = string
  default     = "15"
}

variable "environment" {
  description = "Ambiente"
  type        = string
}

variable "project_name" {
  description = "Nome do projeto"
  type        = string
}