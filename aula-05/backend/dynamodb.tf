# Tabela DynamoDB para locking do Terraform state
# Evita que dois applies simultâneos corrompam o state
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "${var.project_name}-terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name    = "${var.project_name}-terraform-locks"
    Project = "TechNova"
    Purpose = "Terraform Remote State"
    Aula    = "05"
  }
}
