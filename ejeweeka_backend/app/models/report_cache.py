from sqlalchemy import Column, Integer, String, Float, JSON
from app.db import Base

class ReportCache(Base):
    """
    Таблица для кэширования еженедельных RAG-отчетов.
    Zero-Knowledge: привязывается к хэшу входных параметров, а не к UUID пользователя.
    """
    __tablename__ = "reports_library"

    id = Column(Integer, primary_key=True, index=True)
    parameters_hash = Column(String(64), unique=True, index=True, nullable=False)
    health_score = Column(Float, nullable=False)
    report_json = Column(JSON, nullable=False)
