terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.75"
    }
    # random usado apenas pelo random_id do bucket (comentado em s3.tf).
    # Reative junto com o bucket caso rode fora do Learner Lab.
    # random = {
    #   source  = "hashicorp/random"
    #   version = "~> 3.0"
    # }
  }
}

provider "aws" {
  region = var.aws_region
}
