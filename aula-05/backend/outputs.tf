# O bucket S3 e criado via AWS CLI (ver s3.tf — SCP do Learner Lab impede
# gerencia-lo via Terraform). O nome do bucket usado no backend "s3" do projeto
# principal e: technova-terraform-state-f6c1c8ee
#
# Outputs do bucket ficam comentados porque o recurso nao e gerenciado por este
# state. A tabela DynamoDB de locking, essa sim, e gerenciada por Terraform.

# output "s3_bucket_name" {
#   description = "Nome do bucket S3 para o Terraform state"
#   value       = aws_s3_bucket.terraform_state.bucket
# }

# output "s3_bucket_arn" {
#   description = "ARN do bucket S3"
#   value       = aws_s3_bucket.terraform_state.arn
# }

output "dynamodb_table_name" {
  description = "Nome da tabela DynamoDB para locking"
  value       = aws_dynamodb_table.terraform_locks.name
}
