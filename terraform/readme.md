# Infraestructura AWS con Terraform

Este proyecto contiene la infraestructura completa para desplegar una aplicación web en AWS usando Terraform.

## 🚀 Inicio Rápido

### 1. Inicializar Terraform
```bash
terraform init
```

### 2. Revisar el plan
```bash
terraform plan
```

### 3. Desplegar
```bash
terraform apply
```

### 4. Obtener outputs
```bash
terraform output
```

## 📦 Recursos Principales

- **VPC** con subnets públicas y privadas en 2 AZs
- **Application Load Balancer (ALB)** con soporte HTTPS
- **ECS Fargate** para contenedores
- **ECR** para imágenes Docker
- **RDS MySQL** (Free Tier) en subnets privadas
- **AWS Secrets Manager** para credenciales
- **CloudWatch** para logs y monitoreo

## 🔒 Seguridad

- ✅ RDS completamente privado (no accesible desde internet)
- ✅ Credenciales en Secrets Manager
- ✅ Cifrado habilitado
- ✅ Security Groups con principio de menor privilegio

## 📖 Documentación Completa

Para documentación detallada de todos los recursos, configuración, seguridad y mejores prácticas, consulta:

👉 **[INFRASTRUCTURE.md](./INFRASTRUCTURE.md)**

## 🔑 Acceder a Credenciales de Base de Datos

```bash
# Ver todas las credenciales
aws secretsmanager get-secret-value \
  --secret-id proyecto-cicd-dev-db-credentials \
  --query SecretString --output text | jq .

# Solo la contraseña
aws secretsmanager get-secret-value \
  --secret-id proyecto-cicd-dev-db-credentials \
  --query SecretString --output text | jq -r .password
```

## 🧹 Limpieza

Para destruir todos los recursos:
```bash
terraform destroy
```

⚠️ **Advertencia:** Esto eliminará todos los recursos incluyendo la base de datos.

## 📝 Variables Importantes

Crea un archivo `terraform.tfvars` para personalizar:

```hcl
project_name = "mi-proyecto"
environment  = "dev"
aws_region   = "us-east-1"

# RDS
db_name = "mi_base_datos"
db_instance_class = "db.t3.micro"

# ECS
app_count = 1
fargate_cpu = "256"
fargate_memory = "512"
```

## 💰 Costos

- **Free Tier (12 meses):** RDS db.t3.micro, ALB, ECR
- **Estimado mensual:** ~$110/mes (después del Free Tier)
- **Mayor costo:** NAT Gateway (~$64/mes)

Ver [INFRASTRUCTURE.md](./INFRASTRUCTURE.md) para optimización de costos.

