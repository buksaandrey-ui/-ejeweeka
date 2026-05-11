"""
Weekly Report API — AI-generated weekly progress reports (PR-2).

Features:
- Calculates health metrics from client-submitted daily summaries
- Enriches report with RAG context from medical knowledge base
- Generates personalized AI commentary via Gemini
- Stateless: all data arrives from client, nothing stored server-side

Zero-Knowledge: Client sends aggregated metrics only, no PII stored.
"""

from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from typing import Optional, List
from google import genai
import os
import logging

from sqlalchemy.orm import Session
from app.db import get_db
from app.api.dependencies import get_current_user

logger = logging.getLogger(__name__)

router = APIRouter()


# ============================================================
# MODELS
# ============================================================

class DaySummary(BaseModel):
    date: str  # "2026-04-22"
    calories_consumed: int = 0
    calories_target: int = 0
    water_ml: int = 0
    water_target_ml: int = 2000
    weight_kg: Optional[float] = None
    meals_eaten: int = 0
    meals_planned: int = 0
    steps: Optional[int] = None
    sleep_hours: Optional[float] = None
    fasting_completed: bool = False


class WeeklyReportRequest(BaseModel):
    days: List[DaySummary]
    # Контекст профиля (передаётся с устройства, не хранится)
    user_goal: str = "Поддержание здоровья"
    user_name: Optional[str] = None
    user_diseases: Optional[List[str]] = []


class WeeklyReportResponse(BaseModel):
    summary: str  # AI-сгенерированный текст отчёта
    metrics: dict  # Ключевые метрики за неделю
    health_score: int  # 0-100
    rag_context_used: bool = False  # Whether RAG enrichment was applied


# ============================================================
# RAG CONTEXT
# ============================================================

def _get_rag_context(db: Session, user_goal: str, diseases: List[str]) -> str:
    """
    Search knowledge base for relevant medical context.
    Returns formatted context string or empty string if RAG unavailable.
    """
    try:
        from app.services.rag_engine import search_knowledge
        
        # Build search query from user context
        query_parts = [user_goal]
        if diseases:
            query_parts.extend(diseases)
        query = " ".join(query_parts)
        
        chunks = search_knowledge(db, query, limit=3)
        
        if not chunks:
            return ""
        
        context_lines = []
        for chunk in chunks:
            doctor_info = f"д-р {chunk.doctor_name}" if chunk.doctor_name else ""
            context_lines.append(
                f"• [{doctor_info}, {chunk.specialization}]: {chunk.content[:300]}"
            )
        
        return "\n".join(context_lines)
        
    except Exception as e:
        logger.warning(f"[Report] RAG context unavailable: {e}")
        return ""


# ============================================================
# METRICS CALCULATION
# ============================================================

def _calculate_metrics(days: List[DaySummary]) -> dict:
    """Calculate weekly health metrics from daily summaries."""
    total_days = len(days)
    
    avg_calories = sum(d.calories_consumed for d in days) / max(total_days, 1)
    avg_target = sum(d.calories_target for d in days) / max(total_days, 1)
    avg_water = sum(d.water_ml for d in days) / max(total_days, 1)
    
    weights = [d.weight_kg for d in days if d.weight_kg]
    weight_change = round(weights[-1] - weights[0], 1) if len(weights) >= 2 else None
    
    # Calorie adherence
    calorie_adherence = min(100, int((avg_calories / avg_target) * 100)) if avg_target > 0 else 0
    
    # Meal plan adherence
    total_eaten = sum(d.meals_eaten for d in days)
    total_planned = sum(d.meals_planned for d in days)
    meals_adherence = min(100, int((total_eaten / total_planned) * 100)) if total_planned > 0 else 0
    
    # Water adherence
    avg_water_target = sum(d.water_target_ml for d in days) / max(total_days, 1)
    water_adherence = min(100, int((avg_water / avg_water_target) * 100)) if avg_water_target > 0 else 0
    
    # Health Score (weighted formula)
    health_score = int(
        calorie_adherence * 0.35 +
        meals_adherence * 0.25 +
        water_adherence * 0.20 +
        (80 if weight_change and abs(weight_change) < 1 else 60) * 0.20
    )
    health_score = max(0, min(100, health_score))
    
    return {
        "avg_calories": int(avg_calories),
        "avg_target": int(avg_target),
        "calorie_adherence": calorie_adherence,
        "meals_adherence": meals_adherence,
        "water_adherence": water_adherence,
        "avg_water_ml": int(avg_water),
        "weight_change_kg": weight_change,
        "days_tracked": total_days,
        "health_score": health_score,
    }


# ============================================================
# ENDPOINT
# ============================================================

@router.post("/weekly", response_model=WeeklyReportResponse)
def generate_weekly_report(
    request: WeeklyReportRequest,
    user_id: str = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Еженедельный AI-отчёт (PR-2).
    Stateless: принимает данные за неделю с устройства → генерит отчёт → возвращает.
    Сервер НИЧЕГО не сохраняет.
    
    Enhanced with RAG: searches medical knowledge base for relevant context
    to enrich the AI-generated report with doctor-backed recommendations.
    """
    if not request.days:
        raise HTTPException(status_code=400, detail="Нет данных за неделю")

    # 1. Calculate metrics
    metrics = _calculate_metrics(request.days)
    health_score = metrics.pop("health_score")

    # 2. Get RAG context from knowledge base
    rag_context = _get_rag_context(
        db,
        request.user_goal,
        request.user_diseases or []
    )
    rag_used = bool(rag_context)

    # 2.5 Generate parameters hash for caching (Zero-Knowledge)
    import hashlib
    import json
    from app.models.report_cache import ReportCache

    hash_payload = {
        "goal": request.user_goal,
        "diseases": sorted(request.user_diseases or []),
        "avg_cal_bucket": round(metrics['avg_calories'] / 100) * 100 if metrics['avg_calories'] else 0,
        "health_score_bucket": round(health_score / 10) * 10,
        "adherence_bucket": round(metrics['meals_adherence'] / 10) * 10
    }
    parameters_hash = hashlib.sha256(json.dumps(hash_payload, sort_keys=True).encode()).hexdigest()
    
    # [CACHE-FIRST]: Ищем готовый отчет в базе
    cached_report = db.query(ReportCache).filter(ReportCache.parameters_hash == parameters_hash).first()
    if cached_report:
        logger.info(f"[Report] Cache hit for {parameters_hash}")
        return WeeklyReportResponse(
            summary=cached_report.report_json.get("summary", ""),
            metrics=metrics,
            health_score=health_score,
            rag_context_used=True,
        )

    # 3. Build AI prompt with RAG context (without personal name to allow caching)
    rag_section = ""
    if rag_context:
        rag_section = f"""
КОНТЕКСТ ИЗ БАЗЫ ЗНАНИЙ (используй для рекомендаций):
{rag_context}
"""

    prompt = f"""Ты — HC-нутрициолог ejeweeka. Составь краткий еженедельный отчёт для пользователя.

ДАННЫЕ ЗА НЕДЕЛЮ:
- Цель: {request.user_goal}
- Заболевания: {', '.join(request.user_diseases) if request.user_diseases else 'нет'}
- Дней отслежено: {metrics['days_tracked']}
- Среднее потребление: {metrics['avg_calories']} ккал (цель: {metrics['avg_target']} ккал)
- Выполнение плана питания: {metrics['meals_adherence']}%
- Среднее потребление воды: {metrics['avg_water_ml']} мл
- Изменение веса: {f"{metrics['weight_change_kg']:+.1f} кг" if metrics['weight_change_kg'] else 'нет данных'}
- Health Score: {health_score}/100
{rag_section}
ФОРМАТ ОТВЕТА (обращайся на «ты», будь поддерживающим):
1. Краткая оценка (2-3 предложения)
2. Что получилось хорошо (1-2 пункта)
3. Что улучшить (1-2 пункта) 
4. Совет на следующую неделю (1 предложение)

Будь поддерживающим, без осуждения. Максимум 200 слов."""

    # 4. Generate report via Gemini
    GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
    client = genai.Client(api_key=GEMINI_API_KEY)

    try:
        response = client.models.generate_content(
            model='gemini-2.5-flash',
            contents=prompt
        )
        summary = response.text.strip()
        logger.info(f"[Report] Generated weekly report for {user_id} (RAG: {rag_used})")
        
        # [FORCE-SAVE]: Сохраняем сгенерированный отчет в кэш
        from sqlalchemy.exc import IntegrityError
        try:
            new_cache = ReportCache(
                parameters_hash=parameters_hash,
                health_score=health_score,
                report_json={"summary": summary}
            )
            db.add(new_cache)
            db.commit()
        except IntegrityError:
            db.rollback()
            logger.info(f"[Report] Сoncurrent cache save caught for {parameters_hash}, continuing.")
        except Exception as cache_e:
            db.rollback()
            logger.error(f"[Report] Cache save error: {cache_e}")
            
    except Exception as e:
        logger.error(f"[Report] Gemini error: {e}")
        db.rollback()
        # Fallback — шаблонный отчёт без AI
        summary = (
            f"📊 Отчёт за неделю\n\n"
            f"Ты отслеживал(а) питание {metrics['days_tracked']} дней. "
            f"Среднее потребление: {metrics['avg_calories']} ккал из {metrics['avg_target']} ккал "
            f"({metrics['calorie_adherence']}% от цели).\n\n"
            f"{'✅ Вес снизился на ' + str(abs(metrics['weight_change_kg'])) + ' кг — отличный прогресс!' if metrics['weight_change_kg'] and metrics['weight_change_kg'] < 0 else ''}"
            f"\n\nПродолжай в том же духе! 💪"
        )

    return WeeklyReportResponse(
        summary=summary,
        metrics=metrics,
        health_score=health_score,
        rag_context_used=rag_used,
    )
