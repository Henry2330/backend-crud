#!/usr/bin/env python3
"""Script maestro para limpiar todos los recursos de AWS antes de terraform apply"""
import subprocess
import sys
import os

def run_script(script_name, description):
    """Ejecuta un script de Python y retorna si fue exitoso"""
    print("\n" + "=" * 70)
    print(f"Ejecutando: {description}")
    print("=" * 70)

    try:
        # Obtener el directorio del script actual
        script_dir = os.path.dirname(os.path.abspath(__file__))
        script_path = os.path.join(script_dir, script_name)

        # Ejecutar el script
        result = subprocess.run(
            [sys.executable, script_path],
            capture_output=False,
            text=True
        )

        if result.returncode == 0:
            print(f"\n✓ {description} completado exitosamente")
            return True
        else:
            print(f"\n⚠ {description} terminó con código de salida: {result.returncode}")
            return False

    except Exception as e:
        print(f"\n✗ Error ejecutando {script_name}: {e}")
        return False

if __name__ == "__main__":
    print("=" * 70)
    print("SCRIPT MAESTRO DE LIMPIEZA DE AWS")
    print("=" * 70)
    print("\nEste script ejecutará las siguientes tareas:")
    print("  1. Limpiar secretos en AWS Secrets Manager")
    print("  2. Limpiar reglas de Security Groups")
    print("\nDespués de esto, podrás ejecutar 'terraform apply' sin errores.")

    results = []

    # 1. Limpiar secretos
    results.append(run_script(
        "cleanup_secrets.py",
        "Limpieza de AWS Secrets Manager"
    ))

    # 2. Limpiar security groups
    results.append(run_script(
        "cleanup_security_groups.py",
        "Limpieza de Security Groups"
    ))

    # Resumen final
    print("\n" + "=" * 70)
    print("RESUMEN FINAL")
    print("=" * 70)

    all_success = all(results)

    if all_success:
        print("\n✓ Todas las tareas de limpieza completadas exitosamente!")
        print("\n📝 Próximos pasos:")
        print("   1. Ejecuta: terraform plan")
        print("   2. Revisa los cambios")
        print("   3. Ejecuta: terraform apply")
        sys.exit(0)
    else:
        print("\n⚠ Algunas tareas de limpieza tuvieron problemas")
        print("\n📝 Recomendaciones:")
        print("   1. Revisa los errores arriba")
        print("   2. Puedes intentar ejecutar los scripts individuales")
        print("   3. O ejecutar este script nuevamente")
        sys.exit(1)

