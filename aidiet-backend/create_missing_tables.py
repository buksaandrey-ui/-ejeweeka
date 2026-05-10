from app.db import engine, Base
from app.models.knowledge_base import KnowledgeChunk
from app.models.recipe_cache import RecipeImageCache
from app.models.grocery_price import GroceryPrice
from app.models.subscription import Subscription, ActivationCode

def create_missing():
    print("Создаем новые таблицы (если их нет)...")
    Base.metadata.create_all(bind=engine)
    print("Успех!")

if __name__ == '__main__':
    create_missing()
