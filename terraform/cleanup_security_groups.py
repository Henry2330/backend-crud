import boto3
import sys
from botocore.exceptions import ClientError

def cleanup_security_group(sg_id, region='us-east-1'):
    """
    Elimina un security group específico.
    """
    ec2_client = boto3.client('ec2', region_name=region)

    try:
        # Primero intentamos describir el security group
        response = ec2_client.describe_security_groups(GroupIds=[sg_id])
        sg = response['SecurityGroups'][0]

        print(f"📋 Security Group encontrado:")
        print(f"   ID: {sg['GroupId']}")
        print(f"   Nombre: {sg['GroupName']}")
        print(f"   Reglas de ingress: {len(sg['IpPermissions'])}")
        print(f"   Reglas de egress: {len(sg['IpPermissionsEgress'])}")

        # Eliminar el security group
        print(f"\n🗑️  Eliminando security group...")
        ec2_client.delete_security_group(GroupId=sg_id)
        print(f"✅ Security group {sg_id} eliminado exitosamente.")
        return True

    except ClientError as e:
        error_code = e.response['Error']['Code']

        if error_code == 'InvalidGroup.NotFound':
            print(f"ℹ️  El security group {sg_id} no existe.")
            return True
        elif error_code == 'DependencyViolation':
            print(f"⚠️  El security group {sg_id} tiene dependencias activas.")
            print(f"   Esto es normal si otros recursos lo están usando.")
            print(f"   Terraform lo manejará automáticamente.")
            return True
        else:
            print(f"❌ Error: {e.response['Error']['Message']}")
            return False

    except Exception as e:
        print(f"❌ Error inesperado: {str(e)}")
        return False

def find_security_groups_by_name(name_pattern, region='us-east-1'):
    """
    Busca security groups por nombre.
    """
    ec2_client = boto3.client('ec2', region_name=region)

    try:
        response = ec2_client.describe_security_groups(
            Filters=[
                {
                    'Name': 'group-name',
                    'Values': [f'*{name_pattern}*']
                }
            ]
        )
        return response['SecurityGroups']
    except Exception as e:
        print(f"❌ Error al buscar security groups: {str(e)}")
        return []

def main():
    # Leer configuración
    project_name = "proyecto-cicd"
    environment = "dev"
    region = "us-east-1"

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
    except:
        print("⚠️  Usando valores por defecto.")

    print(f"\n🔧 Limpiando Security Groups")
    print(f"   Proyecto: {project_name}")
    print(f"   Ambiente: {environment}")
    print(f"   Región: {region}")
    print("=" * 60)

    # Buscar el security group del ALB
    alb_sg_name = f"{project_name}-{environment}-alb-sg"

    print(f"\n🔍 Buscando security group: {alb_sg_name}")
    security_groups = find_security_groups_by_name(alb_sg_name, region)

    if not security_groups:
        print(f"ℹ️  No se encontraron security groups con el nombre '{alb_sg_name}'")
        print(f"💡 Puedes intentar ejecutar 'terraform apply' directamente.")
        return

    print(f"\n📋 Se encontraron {len(security_groups)} security group(s):")
    for sg in security_groups:
        print(f"   - {sg['GroupName']} ({sg['GroupId']})")
        print(f"     Reglas de ingress: {len(sg['IpPermissions'])}")
        print(f"     Reglas de egress: {len(sg['IpPermissionsEgress'])}")

    # Eliminar cada security group encontrado
    success_count = 0
    for sg in security_groups:
        print(f"\n{'='*60}")
        if cleanup_security_group(sg['GroupId'], region):
            success_count += 1

    print(f"\n{'='*60}")
    print(f"✅ Proceso completado: {success_count}/{len(security_groups)} security groups procesados.")
    print(f"\n💡 Ahora puedes ejecutar 'terraform apply' nuevamente.")

if __name__ == "__main__":
    main()

