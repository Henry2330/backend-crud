import boto3
import sys
from botocore.exceptions import ClientError

def force_delete_secret(secret_name, region='us-east-1'):
    """
    Fuerza la eliminación inmediata de un secreto de AWS Secrets Manager.
    Si el secreto está programado para eliminación, lo elimina sin período de recuperación.
    """
    client = boto3.client('secretsmanager', region_name=region)

    try:
        # Primero intentamos obtener información del secreto
        response = client.describe_secret(SecretId=secret_name)

        if 'DeletedDate' in response:
            print(f"⚠️  El secreto '{secret_name}' ya está programado para eliminación.")
            print(f"   Fecha de eliminación: {response['DeletedDate']}")
            print(f"   Forzando eliminación inmediata...")

            # Forzar eliminación inmediata (sin período de recuperación)
            client.delete_secret(
                SecretId=secret_name,
                ForceDeleteWithoutRecovery=True
            )
            print(f"✅ Secreto '{secret_name}' eliminado inmediatamente.")
        else:
            print(f"ℹ️  El secreto '{secret_name}' existe pero no está programado para eliminación.")
            print(f"   Eliminando con período de recuperación de 7 días...")

            # Eliminar con período de recuperación mínimo
            client.delete_secret(
                SecretId=secret_name,
                RecoveryWindowInDays=7
            )
            print(f"✅ Secreto '{secret_name}' programado para eliminación en 7 días.")

    except ClientError as e:
        error_code = e.response['Error']['Code']

        if error_code == 'ResourceNotFoundException':
            print(f"ℹ️  El secreto '{secret_name}' no existe. No hay nada que limpiar.")
        elif error_code == 'InvalidRequestException':
            # El secreto ya está siendo eliminado, intentar forzar eliminación
            try:
                client.delete_secret(
                    SecretId=secret_name,
                    ForceDeleteWithoutRecovery=True
                )
                print(f"✅ Secreto '{secret_name}' eliminado inmediatamente.")
            except Exception as ex:
                print(f"❌ Error al forzar eliminación de '{secret_name}': {str(ex)}")
        else:
            print(f"❌ Error al procesar '{secret_name}': {e.response['Error']['Message']}")
            return False

    except Exception as e:
        print(f"❌ Error inesperado con '{secret_name}': {str(e)}")
        return False

    return True

def main():
    # Leer variables de terraform.tfvars para obtener project_name y environment
    project_name = "proyecto-cicd"
    environment = "dev"
    region = "us-east-1"

    # Intentar leer del archivo terraform.tfvars
    try:
        with open('terraform.tfvars', 'r', encoding='utf-8', errors='ignore') as f:
            for line in f:
                if '=' in line and not line.strip().startswith('#'):
                    key, value = line.split('=', 1)
                    key = key.strip()
                    value = value.strip().strip('"').strip("'")

                    if key == 'project_name':
                        project_name = value
                    elif key == 'environment':
                        environment = value
                    elif key == 'aws_region':
                        region = value
    except FileNotFoundError:
        print("⚠️  No se encontró terraform.tfvars, usando valores por defecto.")
    except Exception as e:
        print(f"⚠️  Error al leer terraform.tfvars: {str(e)}. Usando valores por defecto.")

    print(f"\n🔧 Limpiando secretos de AWS Secrets Manager")
    print(f"   Proyecto: {project_name}")
    print(f"   Ambiente: {environment}")
    print(f"   Región: {region}")
    print("=" * 60)

    # Lista de secretos a limpiar
    secrets = [
        f"{project_name}-{environment}-db-credentials",
        f"{project_name}-{environment}-app-config"
    ]

    success_count = 0
    for secret_name in secrets:
        print(f"\n🔍 Procesando: {secret_name}")
        if force_delete_secret(secret_name, region):
            success_count += 1

    print("\n" + "=" * 60)
    print(f"✅ Proceso completado: {success_count}/{len(secrets)} secretos procesados exitosamente.")
    print("\n💡 Ahora puedes ejecutar 'terraform apply' nuevamente.")

if __name__ == "__main__":
    main()

