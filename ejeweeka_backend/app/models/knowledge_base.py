from sqlalchemy import Column, Integer, String, Text
from pgvector.sqlalchemy import Vector
from app.db import Base

class KnowledgeChunk(Base):
    """
    Таблица для хранения выдержек из транскрипций видео врачей.
    Каждый чанк содержит самодостаточный кусок медицинских знаний.
    """
    __tablename__ = "knowledge_chunks"

    id = Column(Integer, primary_key=True, index=True)
    doctor_name = Column(String(255), nullable=False)
    specialization = Column(String(255))
    video_topic = Column(String(500))
    
    # Сам текст (выжимка из лекции)
    content = Column(Text, nullable=False)
    
    # Векторное представление для семантического поиска
    # Новые модели Gemini (например, gemini-embedding-001) отдают 3072 размерности
    embedding = Column(Vector(3072))

class ProcessedVideo(Base):
    """
    Таблица для логирования обработанных видео, чтобы избежать дубликатов
    и пустой траты токенов Gemini при перезапусках пайплайна (Аудио-Слух v4.0).
    """
    __tablename__ = "processed_videos"

    video_id = Column(String(50), primary_key=True, index=True)
    channel_url = Column(String(255))
    title = Column(String(500))
    status = Column(String(50)) # 'success', 'error', 'skipped'
    chunks_extracted = Column(Integer, default=0)
