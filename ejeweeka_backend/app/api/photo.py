from fastapi import APIRouter, UploadFile, File, Form, HTTPException, Request
from pydantic import BaseModel, Field
from google import genai
from google.genai import types
from sqlalchemy.orm import Session
from fastapi import Depends
import os
import json
from dotenv import load_dotenv

from slowapi import Limiter
from slowapi.util import get_remote_address

from app.db import get_db
from app.services.rag_engine import search_knowledge
from app.api.dependencies import get_current_user

load_dotenv()

router = APIRouter()
limiter = Limiter(key_func=get_remote_address)

MAX_PHOTO_SIZE = 10 * 1024 * 1024  # 10 MB


# ============================================================
# RESPONSE SCHEMA
# ============================================================
class Macros(BaseModel):
    proteins: float = Field(description="Примерное количество белков в граммах")
    fats: float = Field(description="Примерное количество жиров в граммах")
    carbs: float = Field(description="Примерное количество углеводов в граммах")
    fiber: float = Field(description="Примерное количество клетчатки в граммах")

class PhotoAnalysisResponse(BaseModel):
    food_name: str = Field(description="Название распознанного блюда/продукта на русском")
    confidence: float = Field(description="Уверенность распознавания от 0.0 до 1.0")
    calories: int = Field(description="Примерная общая калорийность порции в ккал")
    macros: Macros
    portion_grams: int = Field(description="Примерный вес порции в граммах")
    verdict: str = Field(description="Краткий wellness вердикт нутрициолога (2-3 предложения)")
    warnings: list[str] = Field(description="Список предупреждений: аллергены, скрытый сахар, трансжиры, противопоказания. Пустой список если нет угроз.")


# ============================================================
# ANALYZE ENDPOINT
# ============================================================
@router.post("/analyze")
@limiter.limit("20/minute")
async def analyze_photo(
    request: Request,
    photo: UploadFile = File(...),
    goal: str = Form(""),
    allergies: str = Form("[]"),
    diseases: str = Form("[]"),
    daily_calories: int = Form(2000),
    calories_consumed: int = Form(0),
    db: Session = Depends(get_db),
    user_id: str = Depends(get_current_user)
):
    """
    Анализ фото еды через Gemini Vision + RAG-контекст из базы знаний.
    Принимает изображение + контекст профиля пользователя.
    """

    # Валидация типа файла
    if not photo.content_type or not photo.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="Файл должен быть изображением (jpeg/png).")

    try:
        image_bytes = await photo.read()
    except Exception:
        raise HTTPException(status_code=400, detail="Не удалось прочитать изображение.")

    if len(image_bytes) < 1000:
        raise HTTPException(status_code=400, detail="Файл слишком мал для анализа.")
    if len(image_bytes) > MAX_PHOTO_SIZE:
        raise HTTPException(status_code=413, detail=f"Файл слишком большой (макс. 10 МБ, получено {len(image_bytes) // 1024 // 1024} МБ).")

    # Парсинг контекста пользователя
    try:
        user_allergies = json.loads(allergies) if allergies else []
    except json.JSONDecodeError:
        user_allergies = []

    try:
        user_diseases = json.loads(diseases) if diseases else []
    except json.JSONDecodeError:
        user_diseases = []

    calories_remaining = max(0, daily_calories - calories_consumed)

    # Gemini API
    GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
    if not GEMINI_API_KEY:
        raise HTTPException(status_code=500, detail="Gemini API Key не настроен")

    client = genai.Client(api_key=GEMINI_API_KEY)

    # RAG: поиск медицинского контекста
    rag_advice = ""
    rag_search_query = f"Питание, продукты, противопоказания"
    if user_diseases:
        rag_search_query += f" при заболеваниях: {', '.join(user_diseases)}"
    if user_allergies:
        rag_search_query += f". Аллергии: {', '.join(user_allergies)}"

    try:
        rag_results = search_knowledge(db, rag_search_query, limit=5)
        if rag_results:
            rag_advice = "\n".join([
                f"Совет от {r.doctor_name} ({r.specialization}): {r.content}"
                for r in rag_results
            ])
    except Exception as e:
        print(f"⚠️ RAG search failed (non-critical): {e}")
        rag_advice = ""

    # Промпт для Gemini Vision
    user_context = ""
    if goal:
        user_context += f"\n- Цель пользователя: {goal}"
    if user_allergies:
        user_context += f"\n- АЛЛЕРГИИ (КРИТИЧЕСКИ ВАЖНО — предупреди если блюдо содержит): {', '.join(user_allergies)}"
    if user_diseases:
        user_context += f"\n- Заболевания: {', '.join(user_diseases)}"
    user_context += f"\n- Дневная норма: {daily_calories} ккал. Уже съедено: {calories_consumed} ккал. Осталось: {calories_remaining} ккал."

    rag_block = ""
    if rag_advice:
        rag_block = f"""
    ПРОФЕССИОНАЛЬНАЯ БАЗА ЗНАНИЙ (учти при формировании вердикта):
    {rag_advice}
    """

    prompt = f"""
    Ты — клинический диетолог-нутрициолог ejeweeka. Пользователь прислал фото своей еды.

    КОНТЕКСТ ПОЛЬЗОВАТЕЛЯ:{user_context}
    {rag_block}
    ЗАДАЧА:
    1. Определи блюдо/продукт на фото. Если не уверен — укажи наиболее вероятный вариант и поставь низкий confidence.
    2. Оцени размер порции в граммах (визуально, по масштабу тарелки/руки/столовых приборов).
    3. Рассчитай КБЖУ и клетчатку на определённую порцию.
    4. Сформулируй краткий вердикт (2-3 предложения): подходит ли это блюдо пользователю с учётом его цели и здоровья.
    5. Перечисли предупреждения (warnings): аллергены из списка пользователя, скрытый сахар, трансжиры, канцерогены от жарки, высокий ГИ при диабете и т.д. Если угроз нет — пустой список.

    ПРАВИЛА:
    - confidence: 0.0-1.0. Если на фото нечёткое изображение, несколько блюд или неочевидный продукт — ставь ниже 0.70.
    - Вердикт пиши на русском, обращаясь на «ты».
    - В вердикте упомяни влияние на дневной план: «Это {X} ккал из оставшихся {remaining} ккал на сегодня.»
    """

    print(f"📸 Анализируем фото: {photo.filename} ({len(image_bytes)} байт)")

    try:
        response = client.models.generate_content(
            model='gemini-2.5-flash',
            contents=[
                types.Part.from_bytes(data=image_bytes, mime_type=photo.content_type),
                prompt
            ],
            config={
                'response_mime_type': 'application/json',
                'response_schema': PhotoAnalysisResponse,
            }
        )

        result_json = response.text
        if result_json.startswith("```json"):
            result_json = result_json[7:-3].strip()

        data = json.loads(result_json)

        # Добавляем вычисленные поля
        data["calories_remaining"] = calories_remaining - data.get("calories", 0)
        data["rag_context_used"] = len(rag_results) if rag_advice else 0
        data["impact"] = (
            f"Это {data.get('calories', 0)} ккал. "
            f"До конца дня осталось {max(0, calories_remaining - data.get('calories', 0))} ккал."
        )

        return {"status": "success", "data": data}

    except Exception as e:
        print(f"❌ Ошибка Gemini Photo Analysis: {str(e)}")
        raise HTTPException(status_code=500, detail="Ошибка при нейроанализе фотографии")
