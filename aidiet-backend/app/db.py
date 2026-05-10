import os
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base
from dotenv import load_dotenv

load_dotenv()

# Получаем URL из переменной окружения
DATABASE_URL = os.getenv("DATABASE_URL", "")

if not DATABASE_URL:
    DATABASE_URL = "postgresql://postgres:postgres@localhost:5432/aidiet"
else:
    # Удаляем невидимые символы, пробелы и кавычки
    DATABASE_URL = DATABASE_URL.strip().strip("\"'").strip()
    # Исправляем протокол
    if DATABASE_URL.startswith("postgres://"):
        DATABASE_URL = DATABASE_URL.replace("postgres://", "postgresql://", 1)

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

# Зависимость для эндпоинтов
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
