terraform {
  required_version = ">= 1.5"

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

  # Backend remoto S3 (GitOps exige state compartilhado — não pode ser local).
  # Lock via S3 (use_lockfile) — método novo que dispensa a tabela DynamoDB.
  backend "s3" {
    bucket       = "technova-tfstate-6325109-a10"
    key          = "aula-10/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "TechNova"
      Environment = var.environment
      ManagedBy   = "Terraform"
      Owner       = var.owner_ra
      Aula        = "10"
    }
  }
}
