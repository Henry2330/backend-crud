from fastapi import FastAPI, HTTPException, Request
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from typing import List, Optional
from fastapi.middleware.cors import CORSMiddleware
import uvicorn
import os
import socket
from datetime import datetime
import time

start_time = time.time()
app = FastAPI()

# Configuración de CORS - Permitir todos los orígenes
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Permitir todos los orígenes
    allow_credentials=False,  # Debe ser False cuando allow_origins es ["*"]
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],  # Métodos HTTP permitidos
    allow_headers=["*"],  # Permitir todos los headers
    expose_headers=["*"],  # Exponer todos los headers en la respuesta
    max_age=3600,  # Cache preflight por 1 hora
)


class Book(BaseModel):
    id: int
    title: str
    author: str
    year: int
    price: float
    stock: int
    description: Optional[str] = None


books = [
    Book(id=1, title="Cien años de soledad", author="Gabriel García Márquez",
         year=1967, price=19.99, stock=5,
         description="Novela emblemática de la literatura latinoamericana."),
    Book(id=2, title="Don Quijote de la Mancha", author="Miguel de Cervantes",
         year=1605, price=15.50, stock=3,
         description="La obra más importante de la literatura española."),
    Book(id=3, title="1984", author="George Orwell", year=1949, price=12.00, stock=10,
         description="Novela distopica sobre un règimen totalitario.")
]


@app.get("/")
async def root():
    return {
        "success": True,
        "message": "¡Aplicación CI/CD en AWS funcionando correctamente en python!",
        "data": {
            "version": "1.0.0",
            "environment": os.getenv("NODE_ENV", "development"),
            "timestamp": datetime.now().isoformat(),
            "hostname": socket.gethostname()
        }
    }


@app.get("/health")
async def health():
    return {
        "status": "healthy",
        "service": "backend-crud",
        "uptime_seconds": round(time.time() - start_time, 2),
        "timestamp": datetime.now().isoformat(),
        "environment": os.getenv("NODE_ENV", "development"),
        "hostname": socket.gethostname()
    }


@app.get("/api/info")
async def info():
    return {
        "project": "Proyecto Final CI/CD",
        "technology": "Python + FastAPI",
        "cloud": "AWS ECS Fargate",
        "cicd": "GitHub Actions",
        "infrastructure": "Terraform"
    }


@app.get("/error")
async def error_test():
    raise HTTPException(status_code=500, detail="Error de prueba")


@app.exception_handler(404)
async def not_found_handler(request: Request, exc: HTTPException):
    return JSONResponse(
        status_code=404,
        content={"success": False, "message": "Ruta no encontrada"}
    )


@app.get("/books", response_model=List[Book])
async def get_books():
    return books


@app.get("/books/{book_id}", response_model=Book)
async def get_book(book_id: int):
    book = next((b for b in books if b.id == book_id), None)
    if not book:
        raise HTTPException(status_code=404, detail="Libro no encontrado")
    return book


@app.post("/books", response_model=Book)
async def create_book(book: Book):
    if any(b.id == book.id for b in books):
        raise HTTPException(status_code=400, detail="Ya existe un libro con este ID")
    books.append(book)
    return book


@app.put("/books/{book_id}", response_model=Book)
async def update_book(book_id: int, book: Book):
    index = next((i for i, b in enumerate(books) if b.id == book_id), None)
    if index is None:
        raise HTTPException(status_code=404, detail="Libro no encontrado")
    books[index] = book
    return book


@app.delete("/books/{book_id}", response_model=Book)
async def delete_book(book_id: int):
    index = next((i for i, b in enumerate(books) if b.id == book_id), None)
    if index is None:
        raise HTTPException(status_code=404, detail="Libro no encontrado")
    return books.pop(index)


if __name__ == "__main__":
    PORT = int(os.getenv("PORT", 3000))
    ENV = os.getenv("NODE_ENV", "development")
    print(f"Servidor corriendo en puerto {PORT}")
    print(f"Ambiente: {ENV}")
    print(f"Iniciado: {datetime.now().isoformat()}")
    uvicorn.run("main:app", host="0.0.0.0", port=PORT, reload=True)
