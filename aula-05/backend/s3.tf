# =============================================================================
# BUCKET S3 PARA O TERRAFORM STATE (Remote State)
# =============================================================================
# ATENCAO — Learner Lab (AWS Academy):
# A Service Control Policy (SCP) da conta nega s3:GetBucketObjectLockConfiguration.
# O provider AWS chama essa acao automaticamente ao criar/atualizar (refresh) um
# bucket S3, retornando 403 AccessDenied. Isso torna IMPOSSIVEL gerenciar o bucket
# via Terraform nesta conta.
#
# Por isso, neste ambiente o bucket e criado/configurado via AWS CLI (mesmas
# propriedades declaradas abaixo): versionamento, encriptacao AES256 e block
# public access. O bloco de codigo abaixo permanece como REFERENCIA do resultado
# desejado (Infra as Code documentada) e fica comentado para que
# `terraform apply` no backend gerencie apenas a tabela DynamoDB de locking.
#
# Comandos equivalentes usados (ver README):
#   aws s3api create-bucket --bucket <nome> --region us-east-1
#   aws s3api put-bucket-versioning --bucket <nome> --versioning-configuration Status=Enabled
#   aws s3api put-bucket-encryption --bucket <nome> --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
#   aws s3api put-public-access-block --bucket <nome> --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
# =============================================================================

# resource "random_id" "suffix" {
#   byte_length = 4
# }
#
# resource "aws_s3_bucket" "terraform_state" {
#   bucket = "${var.project_name}-terraform-state-${random_id.suffix.hex}"
#
#   versioning {
#     enabled = true
#   }
#
#   server_side_encryption_configuration {
#     rule {
#       apply_server_side_encryption_by_default {
#         sse_algorithm = "AES256"
#       }
#     }
#   }
#
#   tags = {
#     Name    = "${var.project_name}-terraform-state"
#     Project = "TechNova"
#     Purpose = "Terraform Remote State"
#     Aula    = "05"
#   }
# }
#
# resource "aws_s3_bucket_public_access_block" "terraform_state" {
#   bucket = aws_s3_bucket.terraform_state.id
#
#   block_public_acls       = true
#   block_public_policy     = true
#   ignore_public_acls      = true
#   restrict_public_buckets = true
# }
