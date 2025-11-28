# Certificado SSL/TLS Autofirmado
# Este recurso se usa cuando enable_https es true pero no hay certificado ni dominio configurado

# 1. Generar una clave privada
resource "tls_private_key" "self_signed" {
  count     = var.enable_https && var.certificate_arn == "" && var.domain_name == "" ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 2048
}

# 2. Crear un certificado autofirmado
resource "tls_self_signed_cert" "self_signed" {
  count           = var.enable_https && var.certificate_arn == "" && var.domain_name == "" ? 1 : 0
  private_key_pem = tls_private_key.self_signed[0].private_key_pem

  subject {
    common_name  = "*.${var.project_name}-${var.environment}.local"
    organization = var.project_name
  }

  validity_period_hours = 8760 # 1 año

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]

  dns_names = [
    "localhost",
    "*.${var.project_name}-${var.environment}.local",
    "${var.project_name}-${var.environment}.local",
  ]

  ip_addresses = [
    "127.0.0.1",
  ]
}

# 3. Importar el certificado autofirmado a ACM
resource "aws_acm_certificate" "self_signed" {
  count             = var.enable_https && var.certificate_arn == "" && var.domain_name == "" ? 1 : 0
  private_key       = tls_private_key.self_signed[0].private_key_pem
  certificate_body  = tls_self_signed_cert.self_signed[0].cert_pem

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-self-signed-cert"
    Environment = var.environment
    Type        = "Self-Signed"
  }
}

