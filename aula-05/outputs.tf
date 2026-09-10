output "vpc_id" {
  description = "ID da VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "ID da subnet pública (EC2)"
  value       = aws_subnet.public.id
}

output "private_subnet_ids" {
  description = "IDs das subnets privadas (RDS)"
  value       = [aws_subnet.private_1.id, aws_subnet.private_2.id]
}

output "rds_endpoint" {
  description = "Endpoint de conexão do RDS (host:porta)"
  value       = aws_db_instance.main.endpoint
}

output "rds_address" {
  description = "Hostname do RDS (sem porta)"
  value       = aws_db_instance.main.address
}

output "rds_port" {
  description = "Porta do RDS"
  value       = aws_db_instance.main.port
}

output "rds_database_name" {
  description = "Nome do banco de dados"
  value       = aws_db_instance.main.db_name
}

output "ec2_public_ip" {
  description = "IP público do EC2"
  value       = aws_instance.api.public_ip
}

output "api_url" {
  description = "URL da API TechNova"
  value       = "http://${aws_instance.api.public_ip}:3000"
}

output "ssh_command" {
  description = "Comando SSH para conectar ao EC2"
  value       = "ssh -i ${var.project_name}-key.pem ec2-user@${aws_instance.api.public_ip}"
}

output "connection_string" {
  description = "Comando psql para conectar do EC2 ao RDS"
  value       = "psql -h ${aws_db_instance.main.address} -U ${var.db_username} -d ${var.db_name} -p ${aws_db_instance.main.port}"
  sensitive   = false
}
