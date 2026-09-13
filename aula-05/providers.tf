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

  # Backend S3 — Remote State com locking via DynamoDB
  # Bucket S3 criado/configurado via AWS CLI (versionamento, encriptação AES256,
  # block public access) porque a SCP do AWS Academy nega
  # s3:GetBucketObjectLockConfiguration, impedindo o Terraform de gerenciar o bucket.
  # A tabela DynamoDB de locking é gerenciada por Terraform em backend/.
  # Inicialização: terraform init  (state gravado direto no S3).
  backend "s3" {
    bucket         = "technova-terraform-state-f6c1c8ee"
    key            = "aula-05/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "technova-terraform-locks"
  }
}

provider "aws" {
  region = var.aws_region
}
