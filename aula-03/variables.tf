variable "aws_region" {
  description = "Região da AWS onde os recursos serão criados"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Ambiente do projeto"
  type        = string
  default     = "development"
}

variable "project_name" {
  description = "Nome do projeto"
  type        = string
  default     = "technova"
}

variable "iam_users" {
  description = "Lista de usuários IAM a serem criados"
  type        = list(string)
  default     = ["dev-joao", "dev-maria", "devops-carlos", "devops-ana", "readonly-marcos"]
}
