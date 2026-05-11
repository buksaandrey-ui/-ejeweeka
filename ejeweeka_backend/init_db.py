from app.db import engine, Base
# Импорт обязателен, чтобы SQLAlchemy увидел структуру таблицы перед созданием
from app.models.knowledge_base import KnowledgeChunk
from app.models.recipe_cache import RecipeImageCache
from app.models.grocery_price import GroceryPrice
def init_db():
    print("Удаляем старую таблицу (768) и создаем новую (3072) в Supabase...")
    Base.metadata.drop_all(bind=engine)
    # Создать все таблицы, описанные в Base
    Base.metadata.create_all(bind=engine)
    print("Готово! Таблица knowledge_chunks с векторным полем успешно создана в облаке.")

if __name__ == "__main__":
    init_db()
