terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }

  # Backend S3 — configurado após criar a infraestrutura de backend
  # Para ativar:
  # 1. Execute terraform apply na pasta backend/ e anote os outputs
  # 2. Descomente o bloco abaixo com os valores corretos
  # 3. Execute: terraform init -migrate-state

  # Backend S3 — configurado apos criar a infraestrutura de backend
  # Para ativar:
  # 1. Crie o bucket S3 e a tabela DynamoDB (via backend/ ou AWS CLI)
  # 2. Descomente o bloco abaixo com o nome real do bucket
  # 3. Execute: terraform init -migrate-state
  #
  # backend "s3" {
  #   bucket         = "technova-terraform-state-XXXXXXXX"
  #   key            = "aula-05/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "technova-terraform-locks"
  # }
}

provider "aws" {
  region = var.aws_region
}
