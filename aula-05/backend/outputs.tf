output "s3_bucket_name" {
  description = "Nome do bucket S3 para o Terraform state"
  value       = aws_s3_bucket.terraform_state.bucket
}

output "s3_bucket_arn" {
  description = "ARN do bucket S3"
  value       = aws_s3_bucket.terraform_state.arn
}

output "dynamodb_table_name" {
  description = "Nome da tabela DynamoDB para locking"
  value       = aws_dynamodb_table.terraform_locks.name
}
