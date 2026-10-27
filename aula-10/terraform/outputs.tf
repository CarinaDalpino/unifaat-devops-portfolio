output "vpc_id" {
  description = "ID da VPC criada"
  value       = aws_vpc.main.id
}

output "api_security_group_id" {
  description = "ID do Security Group da API"
  value       = aws_security_group.api.id
}

output "ec2_public_ip" {
  description = "IP público da EC2 (usar no secret EC2_HOST)"
  value       = aws_instance.api.public_ip
}

output "api_url" {
  description = "URL da API TechNova"
  value       = "http://${aws_instance.api.public_ip}:${var.api_port}"
}

output "health_url" {
  description = "URL do health check"
  value       = "http://${aws_instance.api.public_ip}:${var.api_port}/health"
}

output "ecr_repository_url" {
  description = "URL do repositório ECR (destino do build+push)"
  value       = aws_ecr_repository.technova_api.repository_url
}

output "ssh_command" {
  description = "Comando SSH para conectar na EC2"
  value       = "ssh ubuntu@${aws_instance.api.public_ip}"
}
