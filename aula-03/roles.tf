# ─── Service Role para EC2 ────────────────────────────────────────────────────
# Permite que instâncias EC2 assumam este role para acessar S3
# Usa credenciais temporárias — mais seguro que access keys no código

# Trust Policy — define quem pode assumir este role (EC2)
resource "aws_iam_role" "ec2_s3_role" {
  name        = "${var.project_name}-ec2-s3-role"
  description = "Role para instâncias EC2 da TechNova acessarem o S3 sem access keys"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EC2AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Anexar a policy de S3 ao role da EC2
resource "aws_iam_role_policy_attachment" "ec2_s3_policy" {
  role       = aws_iam_role.ec2_s3_role.name
  policy_arn = aws_iam_policy.developer_s3_policy.arn
}

# Anexar policy de CloudWatch ao role da EC2 (para enviar logs)
resource "aws_iam_role_policy_attachment" "ec2_cloudwatch_policy" {
  role       = aws_iam_role.ec2_s3_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# ─── Instance Profile ─────────────────────────────────────────────────────────
# O Instance Profile é o "envelope" que permite associar um role a uma instância EC2
# Sem ele, não é possível atribuir o role à EC2 no momento do lançamento
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-ec2-instance-profile"
  role = aws_iam_role.ec2_s3_role.name
}
