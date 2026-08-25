# ─── Outputs — IAM Users ──────────────────────────────────────────────────────
output "iam_user_names" {
  description = "Nomes dos usuários IAM criados"
  value       = [for user in aws_iam_user.technova_users : user.name]
}

output "iam_user_arns" {
  description = "ARNs dos usuários IAM criados"
  value       = [for user in aws_iam_user.technova_users : user.arn]
}

# ─── Outputs — IAM Groups ─────────────────────────────────────────────────────
output "group_developers_arn" {
  description = "ARN do grupo de desenvolvedores"
  value       = aws_iam_group.developers.arn
}

output "group_devops_arn" {
  description = "ARN do grupo DevOps"
  value       = aws_iam_group.devops.arn
}

output "group_readonly_arn" {
  description = "ARN do grupo somente leitura"
  value       = aws_iam_group.readonly.arn
}

# ─── Outputs — IAM Role ───────────────────────────────────────────────────────
output "ec2_role_arn" {
  description = "ARN do role para instâncias EC2"
  value       = aws_iam_role.ec2_s3_role.arn
}

output "ec2_instance_profile_arn" {
  description = "ARN do instance profile para EC2"
  value       = aws_iam_instance_profile.ec2_profile.arn
}

# ─── Outputs — Policies ───────────────────────────────────────────────────────
output "policy_developer_s3_arn" {
  description = "ARN da policy de S3 para desenvolvedores"
  value       = aws_iam_policy.developer_s3_policy.arn
}

output "policy_devops_arn" {
  description = "ARN da policy para equipe DevOps"
  value       = aws_iam_policy.devops_policy.arn
}
