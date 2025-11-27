# Usar una imagen base de Python
FROM python:3.11-slim

# Establecer el directorio de trabajo en el contenedor
WORKDIR /app

# Copiar el archivo de dependencias
COPY requirements.txt .

# Instalar las dependencias
RUN pip install --no-cache-dir -r requirements.txt

# Copiar el código de la aplicación
COPY . .

# Exponer el puerto en el que correrá FastAPI
EXPOSE 3000

# Comando para ejecutar la aplicación con uvicorn
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "3000"]

