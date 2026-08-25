# ─── IAM Users ────────────────────────────────────────────────────────────────
# Cria um usuário IAM para cada membro da equipe TechNova
resource "aws_iam_user" "technova_users" {
  for_each = toset(var.iam_users)

  name = "${var.project_name}-${each.key}"

  tags = {
    Name = "${var.project_name}-${each.key}"
    Team = each.key
  }
}

# ─── IAM Groups ───────────────────────────────────────────────────────────────
# Grupo para desenvolvedores — acesso a S3 e logs
resource "aws_iam_group" "developers" {
  name = "${var.project_name}-developers"
}

# Grupo para engenheiros DevOps — acesso a S3, EC2 e IAM read
resource "aws_iam_group" "devops" {
  name = "${var.project_name}-devops"
}

# Grupo para usuários somente leitura
resource "aws_iam_group" "readonly" {
  name = "${var.project_name}-readonly"
}

# ─── Group Memberships ────────────────────────────────────────────────────────
# Desenvolvedores: joao e maria
resource "aws_iam_group_membership" "developers_membership" {
  name  = "${var.project_name}-developers-membership"
  group = aws_iam_group.developers.name

  users = [
    aws_iam_user.technova_users["dev-joao"].name,
    aws_iam_user.technova_users["dev-maria"].name,
  ]
}

# DevOps: carlos e ana
resource "aws_iam_group_membership" "devops_membership" {
  name  = "${var.project_name}-devops-membership"
  group = aws_iam_group.devops.name

  users = [
    aws_iam_user.technova_users["devops-carlos"].name,
    aws_iam_user.technova_users["devops-ana"].name,
  ]
}

# Readonly: marcos
resource "aws_iam_group_membership" "readonly_membership" {
  name  = "${var.project_name}-readonly-membership"
  group = aws_iam_group.readonly.name

  users = [
    aws_iam_user.technova_users["readonly-marcos"].name,
  ]
}

# ─── Attach Policies to Groups ────────────────────────────────────────────────
# Developers: policy customizada de acesso ao S3 + CloudWatch Read
resource "aws_iam_group_policy_attachment" "developers_s3" {
  group      = aws_iam_group.developers.name
  policy_arn = aws_iam_policy.developer_s3_policy.arn
}

resource "aws_iam_group_policy_attachment" "developers_cloudwatch" {
  group      = aws_iam_group.developers.name
  policy_arn = aws_iam_policy.cloudwatch_read_policy.arn
}

# DevOps: policy customizada de DevOps + EC2 Read
resource "aws_iam_group_policy_attachment" "devops_policy" {
  group      = aws_iam_group.devops.name
  policy_arn = aws_iam_policy.devops_policy.arn
}

# Readonly: política AWS gerenciada de somente leitura
resource "aws_iam_group_policy_attachment" "readonly_policy" {
  group      = aws_iam_group.readonly.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}
