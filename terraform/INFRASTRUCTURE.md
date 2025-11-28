# Documentación de Infraestructura con Terraform

## 📋 Índice
1. [Descripción General](#descripción-general)
2. [Arquitectura](#arquitectura)
3. [Recursos Creados](#recursos-creados)
4. [Configuración y Despliegue](#configuración-y-despliegue)
5. [Variables](#variables)
6. [Outputs](#outputs)
7. [Seguridad](#seguridad)
8. [Costos](#costos)

---

## 🎯 Descripción General

Esta infraestructura implementa una aplicación web completa en AWS utilizando Terraform, con los siguientes componentes:

- **VPC** con subnets públicas y privadas
- **Application Load Balancer (ALB)** para distribución de tráfico
- **ECS Fargate** para contenedores sin servidor
- **ECR** para almacenar imágenes Docker
- **RDS MySQL** como base de datos relacional
- **Secrets Manager** para gestión segura de credenciales
- **CloudWatch** para logging y monitoreo
- **ACM** para certificados SSL/TLS

---

## 🏗️ Arquitectura

```
Internet
    ↓
[Internet Gateway]
    ↓
[Application Load Balancer] (Subnets Públicas)
    ↓
[ECS Fargate Tasks] (Subnets Privadas)
    ↓
[RDS MySQL] (Subnets Privadas)
    ↑
[AWS Secrets Manager]
```

**Zonas de Disponibilidad:** La infraestructura se despliega en 2 AZs para alta disponibilidad.

---

## 📦 Recursos Creados

### 1. VPC y Redes (`vpc.tf`)

#### **VPC Principal**
- **Recurso:** `aws_vpc.main`
- **CIDR Block:** `10.0.0.0/16`
- **Propósito:** Red virtual privada que contiene todos los recursos
- **Características:**
  - DNS habilitado
  - Soporte para hostnames DNS

#### **Subnets Públicas** (2)
- **Recurso:** `aws_subnet.public`
- **CIDR Blocks:** `10.0.1.0/24`, `10.0.2.0/24`
- **Propósito:** Alojar recursos accesibles desde internet (ALB, NAT Gateway)
- **Características:**
  - Asignación automática de IPs públicas
  - Distribuidas en 2 zonas de disponibilidad

#### **Subnets Privadas** (2)
- **Recurso:** `aws_subnet.private`
- **CIDR Blocks:** `10.0.10.0/24`, `10.0.11.0/24`
- **Propósito:** Alojar recursos no accesibles desde internet (ECS Tasks, RDS)
- **Características:**
  - Sin IPs públicas
  - Acceso a internet a través de NAT Gateway

#### **Internet Gateway**
- **Recurso:** `aws_internet_gateway.main`
- **Propósito:** Permitir comunicación entre la VPC e Internet

#### **NAT Gateway** (2)
- **Recurso:** `aws_nat_gateway.main`
- **Propósito:** Permitir que recursos privados accedan a internet
- **Características:**
  - Una por zona de disponibilidad
  - Con Elastic IP asociada

#### **Route Tables**
- **Públicas:** Rutas a Internet Gateway
- **Privadas:** Rutas a NAT Gateway

---

### 2. Security Groups (`security-groups.tf`)

#### **Security Group para ALB**
- **Recurso:** `aws_security_group.alb`
- **Propósito:** Controlar tráfico hacia el balanceador de carga
- **Reglas de Entrada:**
  - Puerto 80 (HTTP) desde cualquier origen
  - Puerto 443 (HTTPS) desde cualquier origen
- **Reglas de Salida:** Todo el tráfico permitido

#### **Security Group para ECS Tasks**
- **Recurso:** `aws_security_group.ecs_tasks`
- **Propósito:** Controlar tráfico hacia los contenedores
- **Reglas de Entrada:**
  - Puerto 3000 (app_port) solo desde ALB
- **Reglas de Salida:** Todo el tráfico permitido

#### **Security Group para RDS**
- **Recurso:** `aws_security_group.rds`
- **Propósito:** Controlar acceso a la base de datos
- **Reglas de Entrada:**
  - Puerto 3306 (MySQL) solo desde ECS Tasks
  - Puerto 3306 desde subnets privadas
- **Reglas de Salida:** Todo el tráfico permitido
- **Características de Seguridad:**
  - ✅ Base de datos NO accesible desde internet
  - ✅ Solo accesible desde contenedores ECS
  - ✅ Aislada en subnets privadas

---

### 3. Application Load Balancer (`alb.tf`)

#### **Application Load Balancer**
- **Recurso:** `aws_lb.main`
- **Propósito:** Distribuir tráfico HTTP/HTTPS a los contenedores
- **Características:**
  - Orientado a internet
  - En subnets públicas
  - Soporte para HTTP y HTTPS

#### **Target Group**
- **Recurso:** `aws_lb_target_group.app`
- **Propósito:** Agrupar contenedores ECS
- **Health Check:** `/health`
- **Tipo:** IP (para ECS Fargate)

#### **Listeners**
- **HTTP (80):** Redirige a HTTPS o sirve tráfico directo
- **HTTPS (443):** Con certificado SSL/TLS de ACM

---

### 4. ECS (Elastic Container Service) (`ecs.tf`)

#### **ECS Cluster**
- **Recurso:** `aws_ecs_cluster.main`
- **Propósito:** Agrupar servicios y tareas de contenedores
- **Características:**
  - Container Insights habilitado
  - Fargate como tipo de lanzamiento

#### **Task Definition**
- **Recurso:** `aws_ecs_task_definition.app`
- **Propósito:** Definir la configuración del contenedor
- **Especificaciones:**
  - CPU: 256 unidades (0.25 vCPU)
  - Memoria: 512 MB
  - Network Mode: awsvpc

#### **ECS Service**
- **Recurso:** `aws_ecs_service.app`
- **Propósito:** Mantener el número deseado de tareas ejecutándose
- **Características:**
  - Despliegue en subnets privadas
  - Integrado con ALB
  - Auto Scaling (opcional)

---

### 5. ECR (Elastic Container Registry) (`ecr.tf`)

#### **ECR Repository**
- **Recurso:** `aws_ecr_repository.app`
- **Propósito:** Almacenar imágenes Docker de la aplicación
- **Características:**
  - Escaneo de vulnerabilidades al push
  - Cifrado
  - Políticas de ciclo de vida

---

### 6. RDS MySQL (`rds.tf`)

#### **DB Subnet Group**
- **Recurso:** `aws_db_subnet_group.main`
- **Propósito:** Definir subnets donde RDS puede ejecutarse
- **Ubicación:** Subnets privadas únicamente

#### **Random Password**
- **Recurso:** `random_password.db_password`
- **Propósito:** Generar contraseña segura para la base de datos
- **Características:**
  - Longitud: 16 caracteres
  - Incluye caracteres especiales
  - Almacenada en Secrets Manager

#### **RDS Instance**
- **Recurso:** `aws_db_instance.main`
- **Motor:** MySQL 8.0.35
- **Clase de Instancia:** db.t3.micro (Free Tier)
- **Almacenamiento:** 20 GB GP2 (Free Tier)
- **Propósito:** Base de datos relacional para la aplicación

**Características de Seguridad:**
- ✅ **Privada:** `publicly_accessible = false`
- ✅ **Cifrado:** `storage_encrypted = true`
- ✅ **Subnets Privadas:** Solo accesible desde VPC
- ✅ **Backups:** Retención de 7 días
- ✅ **Monitoring:** Enhanced Monitoring habilitado

**Características de Alta Disponibilidad:**
- ⚠️ **Multi-AZ:** Deshabilitado (para Free Tier)
- ✅ **Auto Minor Version Upgrade:** Habilitado
- ✅ **CloudWatch Logs:** error, general, slowquery

#### **IAM Role para Monitoring**
- **Recurso:** `aws_iam_role.rds_monitoring`
- **Propósito:** Permitir Enhanced Monitoring de RDS
- **Política:** AmazonRDSEnhancedMonitoringRole

---

### 7. AWS Secrets Manager (`secrets.tf`)

#### **Secret: Credenciales de Base de Datos**
- **Recurso:** `aws_secretsmanager_secret.db_credentials`
- **Nombre:** `{project_name}-{environment}-db-credentials`
- **Propósito:** Almacenar credenciales de RDS de forma segura
- **Contenido:**
  ```json
  {
    "username": "admin",
    "password": "<generada-aleatoriamente>",
    "engine": "mysql",
    "host": "<rds-endpoint>",
    "port": 3306,
    "dbname": "appdb",
    "dbInstanceIdentifier": "<rds-id>",
    "connection_string": "mysql://..."
  }
  ```

#### **Secret: Configuración de Aplicación**
- **Recurso:** `aws_secretsmanager_secret.app_config`
- **Nombre:** `{project_name}-{environment}-app-config`
- **Propósito:** Almacenar configuración sensible de la aplicación
- **Contenido:**
  ```json
  {
    "environment": "dev",
    "app_port": 3000,
    "node_env": "development",
    "log_level": "info",
    "db_secret_arn": "<arn-del-secret-db>",
    "aws_region": "us-east-1"
  }
  ```

#### **Políticas de Acceso**
- **Recursos:** `aws_secretsmanager_secret_policy`
- **Propósito:** Permitir que ECS acceda a los secrets
- **Permisos:** `secretsmanager:GetSecretValue` para el role de ECS

**Características de Seguridad:**
- ✅ **Cifrado:** Por defecto con KMS
- ✅ **Políticas de Acceso:** Solo ECS puede leer
- ✅ **Recuperación:** 7 días de ventana de recuperación
- ✅ **Rotación:** Configurable (no implementada por defecto)

---

### 8. IAM Roles y Políticas (`iam.tf`)

#### **ECS Task Execution Role**
- **Recurso:** `aws_iam_role.ecs_task_execution`
- **Propósito:** Permisos para que ECS descargue imágenes y escriba logs
- **Políticas:**
  - AmazonECSTaskExecutionRolePolicy
  - Acceso a Secrets Manager
  - Acceso a ECR

#### **ECS Task Role**
- **Recurso:** `aws_iam_role.ecs_task`
- **Propósito:** Permisos para la aplicación en runtime
- **Políticas:** Personalizables según necesidades

---

### 9. CloudWatch (`cloudwatch.tf`)

#### **Log Group**
- **Recurso:** `aws_cloudwatch_log_group.ecs`
- **Propósito:** Almacenar logs de los contenedores
- **Retención:** 7 días (configurable)

#### **Dashboard**
- **Recurso:** `aws_cloudwatch_dashboard.main`
- **Propósito:** Visualizar métricas de la aplicación
- **Métricas:**
  - CPU y Memoria de ECS
  - Solicitudes y latencia de ALB
  - Conexiones y rendimiento de RDS

#### **Alarmas**
- CPU alta en ECS
- Errores en ALB
- Conexiones a RDS

---

### 10. ACM (AWS Certificate Manager) (`acm.tf`)

#### **Certificado SSL/TLS**
- **Recurso:** `aws_acm_certificate.main`
- **Propósito:** Habilitar HTTPS en el ALB
- **Validación:** DNS
- **Características:**
  - Renovación automática
  - Gratis

---

## ⚙️ Configuración y Despliegue

### Prerrequisitos

```bash
# Terraform >= 1.0
terraform -v

# AWS CLI configurado
aws configure

# Credenciales de AWS con permisos adecuados
```

### Pasos de Despliegue

1. **Inicializar Terraform**
```bash
cd terraform
terraform init
```

2. **Revisar el plan de ejecución**
```bash
terraform plan
```

3. **Aplicar la infraestructura**
```bash
terraform apply
```

4. **Ver los outputs**
```bash
terraform output
```

### Obtener Credenciales de Base de Datos

```bash
# Obtener el secret completo
aws secretsmanager get-secret-value \
  --secret-id proyecto-cicd-dev-db-credentials \
  --query SecretString \
  --output text | jq .

# Solo la contraseña
aws secretsmanager get-secret-value \
  --secret-id proyecto-cicd-dev-db-credentials \
  --query SecretString \
  --output text | jq -r .password
```

---

## 📊 Variables

### Variables Principales

| Variable | Descripción | Valor por Defecto |
|----------|-------------|-------------------|
| `aws_region` | Región de AWS | `us-east-1` |
| `project_name` | Nombre del proyecto | `proyecto-cicd` |
| `environment` | Ambiente (dev/staging/prod) | `dev` |
| `app_port` | Puerto de la aplicación | `3000` |

### Variables de RDS

| Variable | Descripción | Valor por Defecto |
|----------|-------------|-------------------|
| `db_name` | Nombre de la base de datos | `appdb` |
| `db_username` | Usuario maestro | `admin` |
| `db_engine_version` | Versión de MySQL | `8.0.35` |
| `db_instance_class` | Clase de instancia | `db.t3.micro` |
| `db_allocated_storage` | Almacenamiento en GB | `20` |
| `db_backup_retention_period` | Días de retención de backups | `7` |
| `db_skip_final_snapshot` | Saltar snapshot final | `true` |
| `db_deletion_protection` | Protección contra eliminación | `false` |

### Variables de Secrets Manager

| Variable | Descripción | Valor por Defecto |
|----------|-------------|-------------------|
| `secret_recovery_window_days` | Días de recuperación | `7` |
| `app_log_level` | Nivel de logs | `info` |

### Personalización

Crear un archivo `terraform.tfvars`:

```hcl
project_name = "mi-proyecto"
environment  = "prod"
aws_region   = "us-west-2"

# RDS
db_name                   = "produccion_db"
db_instance_class         = "db.t3.small"
db_deletion_protection    = true
db_skip_final_snapshot    = false

# ECS
app_count           = 2
fargate_cpu         = "512"
fargate_memory      = "1024"
autoscaling_enabled = true
```

---

## 📤 Outputs

### Outputs de Red

- `vpc_id`: ID de la VPC
- `public_subnet_ids`: IDs de subnets públicas
- `private_subnet_ids`: IDs de subnets privadas

### Outputs de Aplicación

- `alb_dns_name`: DNS del balanceador
- `alb_url`: URL completa de la aplicación
- `ecr_repository_url`: URL del repositorio Docker

### Outputs de RDS

- `rds_endpoint`: Endpoint completo de la base de datos
- `rds_address`: Host de la base de datos
- `rds_port`: Puerto de la base de datos (3306)
- `rds_database_name`: Nombre de la base de datos
- `rds_username`: Usuario de la base de datos (sensible)

### Outputs de Secrets Manager

- `db_credentials_secret_arn`: ARN del secret de credenciales
- `db_credentials_secret_name`: Nombre del secret de credenciales
- `app_config_secret_arn`: ARN del secret de configuración
- `app_config_secret_name`: Nombre del secret de configuración
- `secrets_manager_console_url`: URL de la consola

### Outputs de Monitoreo

- `cloudwatch_log_group`: Nombre del log group
- `cloudwatch_dashboard_url`: URL del dashboard

---

## 🔒 Seguridad

### Mejores Prácticas Implementadas

#### 1. **Red**
- ✅ Subnets privadas para recursos sensibles (RDS, ECS)
- ✅ Subnets públicas solo para ALB
- ✅ NAT Gateway para acceso a internet desde subnets privadas
- ✅ Security Groups con principio de menor privilegio

#### 2. **Base de Datos**
- ✅ RDS en subnets privadas (no accesible desde internet)
- ✅ Cifrado de datos en reposo
- ✅ Cifrado de datos en tránsito (SSL/TLS)
- ✅ Contraseña generada aleatoriamente
- ✅ Credenciales almacenadas en Secrets Manager
- ✅ Backups automáticos habilitados
- ✅ Enhanced Monitoring habilitado

#### 3. **Secrets Manager**
- ✅ Credenciales nunca en código o variables
- ✅ Cifrado con KMS
- ✅ Políticas de acceso restrictivas
- ✅ Ventana de recuperación para secrets eliminados
- ✅ Rotación de secretos (configurable)

#### 4. **Contenedores**
- ✅ ECS Tasks en subnets privadas
- ✅ Imágenes escaneadas por vulnerabilidades
- ✅ Logs centralizados en CloudWatch
- ✅ IAM roles específicos por tarea

#### 5. **HTTPS/SSL**
- ✅ Certificados SSL/TLS de ACM
- ✅ Renovación automática
- ✅ HTTPS en el ALB

### Recomendaciones Adicionales

#### Para Producción:

1. **Habilitar Multi-AZ en RDS**
```hcl
variable "db_multi_az" {
  default = true  # Para producción
}
```

2. **Habilitar Deletion Protection**
```hcl
variable "db_deletion_protection" {
  default = true  # Para producción
}
```

3. **Guardar Snapshot Final**
```hcl
variable "db_skip_final_snapshot" {
  default = false  # Para producción
}
```

4. **Rotación Automática de Secrets**
```hcl
resource "aws_secretsmanager_secret_rotation" "db_credentials" {
  secret_id           = aws_secretsmanager_secret.db_credentials.id
  rotation_lambda_arn = aws_lambda_function.rotate_secret.arn

  rotation_rules {
    automatically_after_days = 30
  }
}
```

5. **WAF en ALB**
```hcl
resource "aws_wafv2_web_acl_association" "alb" {
  resource_arn = aws_lb.main.arn
  web_acl_arn  = aws_wafv2_web_acl.main.arn
}
```

6. **Guardar Estado de Terraform en S3**
```hcl
backend "s3" {
  bucket         = "mi-bucket-terraform-state"
  key            = "prod/terraform.tfstate"
  region         = "us-east-1"
  encrypt        = true
  dynamodb_table = "terraform-locks"
}
```

---

## 💰 Costos

### Recursos en Free Tier

| Recurso | Free Tier | Duración |
|---------|-----------|----------|
| **RDS MySQL** | db.t3.micro, 20GB, 750 hrs/mes | 12 meses |
| **EC2 (Fargate)** | No aplica directamente | - |
| **ALB** | 750 hrs/mes | 12 meses |
| **Secrets Manager** | 30 días gratis | Luego $0.40/secret/mes |
| **CloudWatch** | 10 métricas, 5GB logs | Siempre gratis |
| **ECR** | 500 MB/mes | 12 meses |

### Estimación de Costos Mensuales (Post Free Tier)

**Configuración Mínima (Dev):**
- RDS db.t3.micro: ~$15/mes
- Fargate (1 task, 0.25 vCPU, 0.5 GB): ~$10/mes
- ALB: ~$20/mes
- Secrets Manager (2 secrets): ~$0.80/mes
- NAT Gateway (2): ~$64/mes
- **Total: ~$110/mes**

**Configuración Producción (con HA):**
- RDS db.t3.small Multi-AZ: ~$60/mes
- Fargate (2 tasks, 0.5 vCPU, 1 GB): ~$40/mes
- ALB: ~$20/mes
- NAT Gateway (2): ~$64/mes
- Secrets Manager: ~$0.80/mes
- CloudWatch: ~$5/mes
- **Total: ~$190/mes**

### Optimización de Costos

1. **Eliminar NAT Gateway en Dev** (usar VPC Endpoints)
2. **Usar RDS Reserved Instances** (ahorro de hasta 60%)
3. **Auto Scaling de ECS** (escalar a 0 fuera de horario)
4. **Spot Instances** para ECS (no recomendado para producción)

---

## 🔧 Mantenimiento

### Actualizar Infraestructura

```bash
# Ver cambios
terraform plan

# Aplicar cambios
terraform apply
```

### Destruir Infraestructura

```bash
# ⚠️ CUIDADO: Esto eliminará todos los recursos
terraform destroy
```

### Backup Manual de RDS

```bash
aws rds create-db-snapshot \
  --db-instance-identifier proyecto-cicd-dev-mysql \
  --db-snapshot-identifier manual-snapshot-$(date +%Y%m%d)
```

### Conectar a RDS (desde instancia EC2 en VPC)

```bash
# Obtener credenciales
DB_HOST=$(terraform output -raw rds_address)
DB_USER=$(terraform output -raw rds_username)
DB_PASS=$(aws secretsmanager get-secret-value \
  --secret-id proyecto-cicd-dev-db-credentials \
  --query SecretString --output text | jq -r .password)

# Conectar
mysql -h $DB_HOST -u $DB_USER -p$DB_PASS appdb
```

---

## 📚 Referencias

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS RDS Best Practices](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_BestPractices.html)
- [AWS Secrets Manager](https://docs.aws.amazon.com/secretsmanager/latest/userguide/intro.html)
- [ECS Best Practices](https://docs.aws.amazon.com/AmazonECS/latest/bestpracticesguide/intro.html)

---

## 👥 Soporte

Para problemas o preguntas:
1. Revisar logs en CloudWatch
2. Verificar Security Groups
3. Validar IAM permissions
4. Consultar documentación de AWS

---

**Última actualización:** 2025-11-24
**Versión de Terraform:** >= 1.0
**Versión de AWS Provider:** ~> 5.0

