# Certificado SSL/TLS con AWS Certificate Manager
# Este recurso se crea solo si se proporciona un domain_name

resource "aws_acm_certificate" "main" {
  count             = var.domain_name != "" && var.certificate_arn == "" ? 1 : 0
  domain_name       = var.domain_name
  validation_method = "DNS"

  subject_alternative_names = [
    "*.${var.domain_name}"
  ]

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-cert"
    Environment = var.environment
  }
}

# Validación del certificado (requiere configuración manual de DNS)
# Nota: Deberás agregar los registros DNS que AWS proporcione en tu proveedor de dominio

