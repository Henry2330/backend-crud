#!/usr/bin/env python3
"""Script para limpiar todas las imágenes de un repositorio ECR"""
import boto3
import sys

def cleanup_ecr_repository(repository_name):
    """Elimina todas las imágenes de un repositorio ECR"""
    ecr_client = boto3.client('ecr')
    
    try:
        # Listar todas las imágenes
        print(f"Listando imágenes en el repositorio: {repository_name}")
        response = ecr_client.list_images(repositoryName=repository_name)
        
        image_ids = response.get('imageIds', [])
        
        if not image_ids:
            print("No hay imágenes para eliminar.")
            return True
        
        print(f"Encontradas {len(image_ids)} imágenes. Eliminando...")
        
        # Eliminar todas las imágenes
        delete_response = ecr_client.batch_delete_image(
            repositoryName=repository_name,
            imageIds=image_ids
        )
        
        deleted = len(delete_response.get('imageIds', []))
        failed = len(delete_response.get('failures', []))
        
        print(f"Imágenes eliminadas: {deleted}")
        if failed > 0:
            print(f"Fallos: {failed}")
            for failure in delete_response.get('failures', []):
                print(f"  - {failure}")
        
        return failed == 0
        
    except Exception as e:
        print(f"Error: {e}")
        return False

if __name__ == "__main__":
    repository_name = "proyecto-cicd-dev-app"
    
    print("=" * 60)
    print("Script de limpieza de ECR")
    print("=" * 60)
    
    success = cleanup_ecr_repository(repository_name)
    
    if success:
        print("\n✓ Limpieza completada exitosamente")
        sys.exit(0)
    else:
        print("\n✗ La limpieza falló")
        sys.exit(1)

