# ─── Policy 1: Developer S3 Access ───────────────────────────────────────────
# Desenvolvedores podem listar e ler/escrever apenas no bucket do projeto
resource "aws_iam_policy" "developer_s3_policy" {
  name        = "${var.project_name}-developer-s3-policy"
  description = "Permite que desenvolvedores leiam e escrevam no bucket S3 do projeto TechNova"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ListProjectBucket"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = "arn:aws:s3:::${var.project_name}-*"
      },
      {
        Sid    = "ReadWriteProjectObjects"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "arn:aws:s3:::${var.project_name}-*/*"
      }
    ]
  })
}

# ─── Policy 2: CloudWatch Read ────────────────────────────────────────────────
# Permite que desenvolvedores leiam logs e métricas — sem poder alterar
resource "aws_iam_policy" "cloudwatch_read_policy" {
  name        = "${var.project_name}-cloudwatch-read-policy"
  description = "Permite leitura de logs e métricas no CloudWatch para monitoramento da aplicação"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CloudWatchReadOnly"
        Effect = "Allow"
        Action = [
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:GetLogEvents",
          "logs:FilterLogEvents",
          "cloudwatch:GetMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics",
          "cloudwatch:DescribeAlarms"
        ]
        Resource = "*"
      }
    ]
  })
}

# ─── Policy 3: DevOps Policy ──────────────────────────────────────────────────
# DevOps tem acesso amplo a S3, EC2 read e pode gerenciar roles/instance profiles
resource "aws_iam_policy" "devops_policy" {
  name        = "${var.project_name}-devops-policy"
  description = "Permissões para equipe DevOps: S3 completo, EC2 read, IAM roles para serviços"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3FullAccess"
        Effect = "Allow"
        Action = [
          "s3:*"
        ]
        Resource = [
          "arn:aws:s3:::${var.project_name}-*",
          "arn:aws:s3:::${var.project_name}-*/*"
        ]
      },
      {
        Sid    = "EC2ReadOnly"
        Effect = "Allow"
        Action = [
          "ec2:Describe*",
          "ec2:Get*",
          "ec2:List*"
        ]
        Resource = "*"
      },
      {
        Sid    = "IAMRolesForServices"
        Effect = "Allow"
        Action = [
          "iam:GetRole",
          "iam:ListRoles",
          "iam:PassRole",
          "iam:ListInstanceProfiles",
          "iam:GetInstanceProfile"
        ]
        Resource = "*"
      }
    ]
  })
}
