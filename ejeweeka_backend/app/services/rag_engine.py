import os
from google import genai
from sqlalchemy.orm import Session
from app.models.knowledge_base import KnowledgeChunk

# Настраиваем Gemini (новый официальный SDK)
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")

if GEMINI_API_KEY and GEMINI_API_KEY.startswith("AIzaSy") and "..." not in GEMINI_API_KEY:
    client = genai.Client(api_key=GEMINI_API_KEY)
else:
    print("ВНИМАНИЕ: Настоящий GEMINI_API_KEY не установлен в .env! Генерация будет падать.")
    client = None

def get_embedding(text: str) -> list[float]:
    """
    Превращает сырой текст медицины в массив чисел (вектор 768 измерений).
    Использует НОВУЮ модель 'text-embedding-004' через новый SDK 'google-genai'.
    """
    if not client:
        raise ValueError("Замени GEMINI_API_KEY в файле .env на настоящий ключ!")
        
    response = client.models.embed_content(
        model="gemini-embedding-001",
        contents=text
    )
    # Возвращаем сам массив чисел
    return response.embeddings[0].values

def add_knowledge_chunk(db: Session, doctor: str, spec: str, topic: str, content: str):
    """
    Добавляет экспертный текст в базу данных. Сначала получает вектор, потом сохраняет.
    """
    vector = get_embedding(content)
    
    chunk = KnowledgeChunk(
        doctor_name=doctor,
        specialization=spec,
        video_topic=topic,
        content=content,
        embedding=vector
    )
    db.add(chunk)
    db.commit()
    db.refresh(chunk)
    return chunk

def search_knowledge(db: Session, query: str, limit: int = 3):
    """
    Главная магия Семантического Поиска.
    Мы переводим запрос юзера в вектор, а потом ищем математически близкие векторы в БД.
    """
    query_vector = get_embedding(query)
    
    # Сортировка по косинусному расстоянию (<=> в pgvector)
    # limit ограничивает кол-во самых релевантных кусков ответа
    results = db.query(KnowledgeChunk).order_by(
        KnowledgeChunk.embedding.cosine_distance(query_vector)
    ).limit(limit).all()
    
    return results
