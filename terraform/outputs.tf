output "vpc_id" {
  description = "ID de la VPC"
  value       = aws_vpc.main.id
}

output "ecr_repository_url" {
  description = "URL del repositorio ECR"
  value       = aws_ecr_repository.app.repository_url
}

output "alb_dns_name" {
  description = "DNS del Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "alb_url" {
  description = "URL completa de la aplicación"
  value       = var.certificate_arn != "" || var.domain_name != "" ? "https://${aws_lb.main.dns_name}" : "http://${aws_lb.main.dns_name}"
}

output "alb_https_url" {
  description = "URL HTTPS de la aplicación (si HTTPS está habilitado)"
  value       = var.certificate_arn != "" || var.domain_name != "" ? "https://${aws_lb.main.dns_name}" : "HTTPS no configurado - Configure certificate_arn o domain_name"
}

output "certificate_arn" {
  description = "ARN del certificado SSL/TLS"
  value       = var.certificate_arn != "" ? var.certificate_arn : try(aws_acm_certificate.main[0].arn, "No certificate configured")
}

output "certificate_validation_records" {
  description = "Registros DNS para validar el certificado (si se creó con ACM)"
  value       = try(aws_acm_certificate.main[0].domain_validation_options, [])
}

output "ecs_cluster_name" {
  description = "Nombre del cluster ECS"
  value       = aws_ecs_cluster.main.name
}

output "ecs_service_name" {
  description = "Nombre del servicio ECS"
  value       = aws_ecs_service.app.name
}

output "cloudwatch_log_group" {
  description = "Nombre del log group de CloudWatch"
  value       = aws_cloudwatch_log_group.ecs.name
}

output "cloudwatch_dashboard_url" {
  description = "URL del dashboard de CloudWatch"
  value       = "https://console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.main.dashboard_name}"
}

# Outputs para RDS
output "rds_endpoint" {
  description = "Endpoint de la base de datos RDS"
  value       = aws_db_instance.main.endpoint
}

output "rds_address" {
  description = "Dirección del host de la base de datos"
  value       = aws_db_instance.main.address
}

output "rds_port" {
  description = "Puerto de la base de datos"
  value       = aws_db_instance.main.port
}

output "rds_database_name" {
  description = "Nombre de la base de datos"
  value       = aws_db_instance.main.db_name
}

output "rds_username" {
  description = "Usuario de la base de datos"
  value       = aws_db_instance.main.username
  sensitive   = true
}

# Outputs para Secrets Manager
output "db_credentials_secret_arn" {
  description = "ARN del secret con las credenciales de la base de datos"
  value       = aws_secretsmanager_secret.db_credentials.arn
}

output "db_credentials_secret_name" {
  description = "Nombre del secret con las credenciales de la base de datos"
  value       = aws_secretsmanager_secret.db_credentials.name
}

output "app_config_secret_arn" {
  description = "ARN del secret con la configuración de la aplicación"
  value       = aws_secretsmanager_secret.app_config.arn
}

output "app_config_secret_name" {
  description = "Nombre del secret con la configuración de la aplicación"
  value       = aws_secretsmanager_secret.app_config.name
}

output "secrets_manager_console_url" {
  description = "URL de la consola de AWS Secrets Manager"
  value       = "https://console.aws.amazon.com/secretsmanager/home?region=${var.aws_region}"
}

