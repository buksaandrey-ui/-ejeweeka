from sqlalchemy import Column, Integer, String, Float, DateTime
from sqlalchemy.sql import func
from app.db import Base

class GroceryPrice(Base):
    """
    Таблица для хранения сгенерированных ИИ (или спарсенных) цен на продукты.
    Позволяет не генерировать денежные метрики "на лету", а брать из базы, 
    что значительно ускоряет сборку плана и оберегает от галлюцинаций LLM.
    """
    __tablename__ = "grocery_prices"

    id = Column(Integer, primary_key=True, index=True)
    country = Column(String(50), index=True, nullable=False)
    city = Column(String(50), index=True, nullable=False)
    product_name = Column(String(100), index=True, nullable=False)
    base_price = Column(Float, nullable=False)         # Обычная цена
    premium_price = Column(Float, nullable=False)      # Цена с наценкой +15% (Азбука Вкуса)
    currency = Column(String(10), nullable=False)      # Например, RUB, USD, EUR
    last_updated = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
