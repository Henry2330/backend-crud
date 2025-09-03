from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List, Optional
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()

# CORS
origins = [
    "http://localhost:5173",
    "http://127.0.0.1:5173"
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Permitir todos los orígenes
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Modelo de libro
class Book(BaseModel):
    id: int
    title: str
    author: str
    year: int
    price: float
    stock: int
    description: Optional[str] = None

# Datos en memoria (se pierden al reiniciar)
books = [
    Book(id=1, title="Cien años de soledad", author="Gabriel García Márquez",
         year=1967, price=19.99, stock=5,
         description="Novela emblemática de la literatura latinoamericana."),
    Book(id=2, title="Don Quijote de la Mancha", author="Miguel de Cervantes",
         year=1605, price=15.50, stock=3,
         description="La obra más importante de la literatura española."),
]

# Obtener todos los libros
@app.get("/books", response_model=List[Book])
async def get_books():
    return books

# Obtener un libro por ID
@app.get("/books/{book_id}", response_model=Book)
async def get_book(book_id: int):
    book = next((b for b in books if b.id == book_id), None)
    if book is None:
        raise HTTPException(status_code=404, detail="Libro no encontrado")
    return book

# Crear un libro
@app.post("/books", response_model=Book)
async def create_book(book: Book):
    if any(b.id == book.id for b in books):
        raise HTTPException(status_code=400, detail="Ya existe un libro con este ID")
    books.append(book)
    return book

# Actualizar un libro
@app.put("/books/{book_id}", response_model=Book)
async def update_book(book_id: int, book: Book):
    index = next((i for i, b in enumerate(books) if b.id == book_id), None)
    if index is None:
        raise HTTPException(status_code=404, detail="Libro no encontrado")
    books[index] = book
    return book

# Eliminar un libro
@app.delete("/books/{book_id}", response_model=Book)
async def delete_book(book_id: int):
    index = next((i for i, b in enumerate(books) if b.id == book_id), None)
    if index is None:
        raise HTTPException(status_code=404, detail="Libro no encontrado")
    return books.pop(index)