## Seguridad

- Los scripts solo limpian recursos que coinciden con el prefijo del proyecto
- No afectan otros proyectos o recursos en tu cuenta AWS
- Siempre revisa el output de los scripts antes de ejecutar `terraform apply`
# Scripts de Limpieza de AWS

## Problema

Al ejecutar `terraform apply`, puedes encontrar los siguientes errores:

1. **Secrets Manager**: Secretos programados para eliminación
   ```
   Error: creating Secrets Manager Secret: a secret with this name is already scheduled for deletion
   ```

2. **Security Groups**: Límite de reglas por security group alcanzado
   ```
   Error: The maximum number of rules per security group has been reached
   ```

## Solución

He creado scripts automáticos para limpiar estos recursos antes de ejecutar Terraform.

### Scripts Disponibles

1. **`cleanup_all.py`** - Script maestro que ejecuta todas las limpiezas
2. **`cleanup_secrets.py`** - Limpia secretos en AWS Secrets Manager
3. **`cleanup_security_groups.py`** - Limpia reglas de Security Groups
4. **`cleanup_aws.bat`** - Script de Windows para facilitar la ejecución

## Uso

### Opción 1: Usar el script batch (Windows - Recomendado)

```cmd
cleanup_aws.bat
```

Este script:
- Verifica que Python esté instalado
- Verifica las credenciales de AWS
- Instala boto3 si no está instalado
- Ejecuta todas las limpiezas automáticamente

### Opción 2: Ejecutar el script Python maestro

```cmd
python cleanup_all.py
```

### Opción 3: Ejecutar scripts individuales

Si solo necesitas limpiar un tipo de recurso específico:

```cmd
# Solo secretos
python cleanup_secrets.py

# Solo security groups
python cleanup_security_groups.py
```

## Requisitos

1. **Python 3.6+** instalado
2. **boto3** instalado:
   ```cmd
   pip install boto3
   ```
3. **AWS CLI configurado** con credenciales válidas:
   ```cmd
   aws configure
   ```

## Qué hacen los scripts

### cleanup_secrets.py
- Lista todos los secretos en Secrets Manager
- Identifica secretos programados para eliminación
- Los recupera temporalmente
- Los elimina permanentemente sin periodo de recuperación
- Permite que Terraform cree nuevos secretos con el mismo nombre

### cleanup_security_groups.py
- Lista todos los security groups del proyecto
- Elimina todas las reglas de ingreso y egreso
- Libera espacio para nuevas reglas
- NO elimina los security groups (solo sus reglas)
- Permite que Terraform recree las reglas correctamente

## Flujo de Trabajo Recomendado

1. Ejecutar limpieza:
   ```cmd
   cleanup_aws.bat
   ```

2. Verificar el plan de Terraform:
   ```cmd
   terraform plan
   ```

3. Aplicar los cambios:
   ```cmd
   terraform apply
   ```

## Notas Importantes

- Los scripts son **seguros** y solo limpian recursos del proyecto especificado
- Los secretos se eliminan **permanentemente** (sin periodo de recuperación)
- Los security groups **no se eliminan**, solo sus reglas
- Si hay recursos activos, algunos security groups no podrán eliminarse (esto es normal)

## Troubleshooting

### "Access Denied" o errores de permisos

Asegúrate de que tu usuario/rol de AWS tiene los siguientes permisos:
- `secretsmanager:DeleteSecret`
- `secretsmanager:RestoreSecret`
- `secretsmanager:ListSecrets`
- `ec2:DescribeSecurityGroups`
- `ec2:RevokeSecurityGroupIngress`
- `ec2:RevokeSecurityGroupEgress`
- `ec2:DeleteSecurityGroup`

### "boto3 not found"

Instala boto3:
```cmd
pip install boto3
```

### "AWS credentials not configured"

Configura AWS CLI:
```cmd
aws configure
```

@echo off
REM Script para limpiar recursos de AWS antes de terraform apply
echo ======================================================================
echo Script de Limpieza de AWS para Windows
echo ======================================================================
echo.

REM Verificar que Python está instalado
python --version >nul 2>&1
if errorlevel 1 (
    echo Error: Python no está instalado o no está en el PATH
    echo Por favor instala Python y asegurate de que esté en el PATH
    pause
    exit /b 1
)

echo Python encontrado!
echo.

REM Verificar que AWS CLI está configurado (boto3 usará las mismas credenciales)
aws sts get-caller-identity >nul 2>&1
if errorlevel 1 (
    echo Advertencia: AWS CLI no está configurado o no tiene credenciales válidas
    echo Asegurate de tener las credenciales configuradas con 'aws configure'
    echo.
)

REM Verificar que boto3 está instalado
python -c "import boto3" >nul 2>&1
if errorlevel 1 (
    echo.
    echo Instalando boto3...
    pip install boto3
    if errorlevel 1 (
        echo Error: No se pudo instalar boto3
        pause
        exit /b 1
    )
)

echo.
echo Ejecutando script de limpieza...
echo.

python cleanup_all.py

if errorlevel 1 (
    echo.
    echo ======================================================================
    echo Hubo algunos errores en la limpieza
    echo ======================================================================
    pause
    exit /b 1
) else (
    echo.
    echo ======================================================================
    echo Limpieza completada exitosamente!
    echo ======================================================================
    echo.
    echo Ahora puedes ejecutar: terraform apply
    echo.
    pause
    exit /b 0
)

