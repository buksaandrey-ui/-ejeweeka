from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from typing import Optional, List
from sqlalchemy.orm import Session
from google import genai
import os

from app.db import get_db
from app.services.rag_engine import search_knowledge
from app.api.dependencies import get_current_user

router = APIRouter()


class ChatMessage(BaseModel):
    role: str  # "user" или "assistant"
    content: str


class ChatRequest(BaseModel):
    message: str
    history: Optional[List[ChatMessage]] = []
    # Контекст пользователя для персонализации (передаётся с устройства)
    user_context: Optional[dict] = None  # {age, gender, goal, diseases, allergies...}


class ChatResponse(BaseModel):
    reply: str
    sources: List[dict] = []  # [{doctor_name, specialization, video_title}]
    tokens_used: Optional[int] = None


SYSTEM_PROMPT = """Ты — HC-нутрициолог ejeweeka. Твоя задача — отвечать на вопросы пользователя 
о питании, здоровье, витаминах и тренировках.

ПРАВИЛА:
1. Отвечай ТОЛЬКО на основе предоставленного медицинского контекста из базы знаний.
2. Если в контексте нет ответа — честно скажи: «В моей базе знаний нет информации по этому вопросу. 
   Рекомендую проконсультироваться с врачом.»
3. НЕ выдумывай медицинские рекомендации.
4. Указывай источник: «По мнению доктора [Имя] ([Специализация])...»
5. Обращайся на «ты».
6. Будь кратким — 2-4 абзаца максимум.
7. НЕ ставь диагнозы. Ты — информационный помощник, не врач.
8. Если вопрос не связан с питанием/здоровьем — вежливо откажи."""


@router.post("/message", response_model=ChatResponse)
def chat_message(request: ChatRequest, db: Session = Depends(get_db), user_id: str = Depends(get_current_user)):
    """
    AI-чат (C-1): вопрос пользователя → RAG-поиск → Gemini → ответ.
    Stateless: история передаётся с клиента, сервер ничего не хранит.
    """

    # 1. RAG-поиск релевантного контекста
    contexts = search_knowledge(db, request.message, limit=5)
    
    sources = []
    context_text = ""
    for c in contexts:
        context_text += f"\nСовет от {c.doctor_name} ({c.specialization}): {c.content}\n"
        sources.append({
            "doctor_name": c.doctor_name,
            "specialization": c.specialization,
            "video_title": getattr(c, 'video_title', '')
        })
    
    if not context_text:
        context_text = "В базе знаний не найдено релевантных материалов по данному вопросу."

    # 2. Формируем промпт
    user_context_str = ""
    if request.user_context:
        uc = request.user_context
        user_context_str = f"""
ПРОФИЛЬ ПОЛЬЗОВАТЕЛЯ (учитывай при ответе):
- Цель: {uc.get('goal', 'не указана')}
- Возраст: {uc.get('age', '?')}, Пол: {uc.get('gender', '?')}
- Заболевания: {', '.join(uc.get('diseases', [])) or 'нет'}
- Аллергии: {', '.join(uc.get('allergies', [])) or 'нет'}
"""

    full_prompt = f"""{SYSTEM_PROMPT}

{user_context_str}

МЕДИЦИНСКИЙ КОНТЕКСТ ИЗ БАЗЫ ЗНАНИЙ:
{context_text}

ИСТОРИЯ ДИАЛОГА:
{chr(10).join([f'{m.role}: {m.content}' for m in (request.history or [])[-5:]])}

ВОПРОС ПОЛЬЗОВАТЕЛЯ: {request.message}

ОТВЕТ:"""

    # 3. Вызываем Gemini
    GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
    client = genai.Client(api_key=GEMINI_API_KEY)

    try:
        response = client.models.generate_content(
            model='gemini-2.5-flash',
            contents=full_prompt
        )
        reply = response.text.strip()
    except Exception as e:
        print(f"[Chat] Gemini error: {e}")
        raise HTTPException(
            status_code=503,
            detail="AI-движок временно недоступен. Попробуй через минуту."
        )

    return ChatResponse(
        reply=reply,
        sources=sources
    )
