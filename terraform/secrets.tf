# Secret para credenciales de la base de datos
resource "aws_secretsmanager_secret" "db_credentials" {
  name        = "${var.project_name}-${var.environment}-db-credentials"
  description = "Credenciales de la base de datos MySQL para ${var.project_name}"

  recovery_window_in_days = var.secret_recovery_window_days

  tags = {
    Name        = "${var.project_name}-${var.environment}-db-credentials"
    Description = "Database credentials"
  }
}

# Versión del secret con las credenciales
resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id

  secret_string = jsonencode({
    username            = aws_db_instance.main.username
    password            = random_password.db_password.result
    engine              = aws_db_instance.main.engine
    host                = aws_db_instance.main.address
    port                = aws_db_instance.main.port
    dbname              = aws_db_instance.main.db_name
    dbInstanceIdentifier = aws_db_instance.main.identifier
    # Connection string completo
    connection_string   = "mysql://${aws_db_instance.main.username}:${random_password.db_password.result}@${aws_db_instance.main.address}:${aws_db_instance.main.port}/${aws_db_instance.main.db_name}"
  })
}

# Secret para configuración de la aplicación
resource "aws_secretsmanager_secret" "app_config" {
  name        = "${var.project_name}-${var.environment}-app-config"
  description = "Configuración de la aplicación para ${var.project_name}"

  recovery_window_in_days = var.secret_recovery_window_days

  tags = {
    Name        = "${var.project_name}-${var.environment}-app-config"
    Description = "Application configuration"
  }
}

# Versión del secret con la configuración de la aplicación
resource "aws_secretsmanager_secret_version" "app_config" {
  secret_id = aws_secretsmanager_secret.app_config.id

  secret_string = jsonencode({
    environment      = var.environment
    app_port         = var.app_port
    node_env         = var.environment == "prod" ? "production" : "development"
    log_level        = var.app_log_level
    # Agregar más configuraciones según sea necesario
    db_secret_arn    = aws_secretsmanager_secret.db_credentials.arn
    aws_region       = var.aws_region
  })
}


