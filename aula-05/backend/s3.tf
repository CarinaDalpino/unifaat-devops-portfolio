# Sufixo aleatório para garantir nome globalmente único
resource "random_id" "suffix" {
  byte_length = 4
}

# Bucket S3 para armazenar o Terraform state
resource "aws_s3_bucket" "terraform_state" {
  bucket = "${var.project_name}-terraform-state-${random_id.suffix.hex}"

  # O AWS Academy Learner Lab (SCP) nega s3:GetBucketObjectLockConfiguration.
  # Declarar explicitamente evita que o provider faca essa chamada bloqueada.
  object_lock_enabled = false

  tags = {
    Name    = "${var.project_name}-terraform-state"
    Project = "TechNova"
    Purpose = "Terraform Remote State"
    Aula    = "05"
  }
}

# Habilitar versionamento (permite rollback do state)
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Encriptação server-side com SSE-S3
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Bloquear todo acesso público ao bucket
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
