# Variables para el proyecto
project_name = "proyecto-cicd"
environment  = "dev"

# ===============================================
# CONFIGURACIÓN HTTPS/SSL
# ===============================================
# Habilitar HTTPS en el ALB
enable_https = true

# OPCIÓN 1: Usar un certificado ARN existente (Recomendado para producción)
# Si ya tienes un certificado en ACM, descomenta y usa su ARN
# certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"

# OPCIÓN 2: Usar un dominio propio con ACM
# Descomenta y reemplaza con tu dominio real
# domain_name = "api.ejemplo.com"
# Después de aplicar, revisa los outputs para obtener los registros DNS
# que debes agregar en tu proveedor de dominio (Route53, GoDaddy, etc.)

# OPCIÓN 3: Certificado autofirmado (Solo para desarrollo/testing)
# Si enable_https = true y NO hay certificate_arn ni domain_name,
# el sistema creará automáticamente un certificado autofirmado
# ⚠️ ADVERTENCIA: Los navegadores mostrarán una advertencia de seguridad
# ⚠️ NO usar en producción

# OPCIÓN 4: Solo HTTP (sin HTTPS)
# Para deshabilitar HTTPS completamente:
# enable_https = false

# ===============================================
# CONFIGURACIÓN CLOUDFRONT CDN
# ===============================================
# Habilitar CloudFront como CDN frente al ALB
# Cuando está habilitado:
# - ALB se vuelve interno (solo accesible desde CloudFront)
# - CloudFront distribuye el contenido globalmente
# - Mejor rendimiento y seguridad
# - Validación de custom header entre CloudFront y ALB
enable_cloudfront = true

# Clase de precio de CloudFront
# PriceClass_100: América del Norte y Europa (más económico)
# PriceClass_200: América, Europa, Asia, Medio Oriente, África
# PriceClass_All: Todas las ubicaciones edge (más cobertura, más costo)
cloudfront_price_class = "PriceClass_100"

# Custom header secreto para validar tráfico desde CloudFront al ALB
# ⚠️ IMPORTANTE: Cambia este valor en producción por uno único y seguro
# Este header se usa para asegurar que solo CloudFront puede acceder al ALB
cloudfront_custom_header_value = "CloudFront-Secret-Header-Value-Change-This"

# Restricción geográfica
# Opciones: "none", "whitelist", "blacklist"
cloudfront_geo_restriction_type = "none"

# Lista de países (códigos ISO 3166-1-alpha-2)
# Ejemplo para whitelist: ["US", "CA", "MX", "CO", "AR", "BR", "ES"]
# Ejemplo para blacklist: ["CN", "RU", "KP"]
cloudfront_geo_restriction_locations = []

# Habilitar AWS WAF para CloudFront
# Proporciona protección contra:
# - Rate limiting (bloqueo de IPs con muchos requests)
# - SQL Injection, XSS, y otras vulnerabilidades comunes
# ⚠️ Costo adicional: AWS WAF tiene cargos por reglas y requests
enable_waf = false

# ===============================================
# EJEMPLO: CONFIGURACIÓN CLOUDFRONT PARA PRODUCCIÓN
# ===============================================
# enable_cloudfront = true
# cloudfront_price_class = "PriceClass_200"
# cloudfront_custom_header_value = "mi-secreto-super-seguro-unico-123456"
# cloudfront_geo_restriction_type = "whitelist"
# cloudfront_geo_restriction_locations = ["US", "CA", "MX", "CO", "AR", "BR"]
# enable_waf = true
