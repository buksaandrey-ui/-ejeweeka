#!/usr/bin/env python3
"""
Master Seed Runner — запускает все seed-скрипты в правильном порядке.
Идемпотентный: каждый скрипт проверяет наличие данных перед вставкой.

Run: python -m app.scripts.seed_all
"""

import sys
import os
import time
from pathlib import Path
from dotenv import load_dotenv

# Находим .env файл рядом с ejeweeka_backend/
_backend_root = Path(__file__).resolve().parent.parent.parent
load_dotenv(_backend_root / ".env")

sys.path.insert(0, str(_backend_root))


def run_step(step_num: int, description: str, func, *args):
    """Run a seed step with timing and error handling."""
    print(f"\n{'='*55}")
    print(f"  ШАГ {step_num}: {description}")
    print(f"{'='*55}")
    start = time.time()
    try:
        func(*args)
        elapsed = time.time() - start
        print(f"  ⏱️  {elapsed:.1f}s")
    except Exception as e:
        print(f"  ❌ ОШИБКА: {e}")
        import traceback
        traceback.print_exc()


def main():
    print("""
╔══════════════════════════════════════════════╗
║  ejeweeka Master Seed Runner v1.0            ║
║  Наполнение всех баз данных                  ║
╚══════════════════════════════════════════════╝
""")

    # Check environment
    db_url = os.getenv("DATABASE_URL")
    gemini_key = os.getenv("GEMINI_API_KEY")

    print(f"  DATABASE_URL:  {'✅ set' if db_url else '❌ missing'}")
    print(f"  GEMINI_API_KEY: {'✅ set' if gemini_key else '⚠️ missing (шаги 1,6 пропущены)'}")

    if not db_url:
        print("\n❌ DATABASE_URL не установлен. Запусти:")
        print("   export DATABASE_URL='postgresql://user:pass@host:5432/dbname'")
        return

    # ─── ШАГ 1: RAG Knowledge Base (requires Gemini for embeddings) ───
    if gemini_key:
        def seed_rag():
            from app.services.rag_engine import add_knowledge_chunk
            from app.db import SessionLocal
            from app.models.knowledge_base import KnowledgeChunk
            from pathlib import Path
            import glob

            db = SessionLocal()
            existing = db.query(KnowledgeChunk).count()
            if existing > 0:
                print(f"  ⚠️ knowledge_chunks уже содержит {existing} записей, пропуск")
                db.close()
                return

            data_dir = Path(__file__).parent.parent.parent / "data" / "transcripts"
            if not data_dir.exists():
                print(f"  ⚠️ {data_dir} не найден, пропуск")
                db.close()
                return

            total = 0
            for folder_path in sorted(data_dir.iterdir()):
                if not folder_path.is_dir():
                    continue
                folder_name = folder_path.name
                if "_" not in folder_name:
                    continue
                spec, doctor = folder_name.split("_", 1)
                doctor = doctor.replace("-", " ").replace("_", " ")

                for file_path in sorted(folder_path.glob("*.txt")):
                    topic = file_path.stem.replace("_", " ")
                    content = file_path.read_text(encoding="utf-8")

                    # Split into chunks ~800 chars
                    paragraphs = [p.strip() for p in content.split("\n") if p.strip()]
                    chunks = []
                    current = ""
                    for p in paragraphs:
                        if len(current) + len(p) < 800:
                            current += p + "\n\n"
                        else:
                            if current:
                                chunks.append(current.strip())
                            current = p + "\n\n"
                    if current:
                        chunks.append(current.strip())

                    for chunk in chunks:
                        try:
                            add_knowledge_chunk(db, doctor, spec, topic, chunk)
                            total += 1
                            time.sleep(3)  # 3s pause to avoid Gemini 429
                        except Exception as e:
                            print(f"    ⚠️ Chunk error: {e}")

            db.close()
            print(f"  ✅ Добавлено {total} чанков в knowledge_chunks")

        run_step(1, "RAG Knowledge Base (embeddings)", seed_rag)
    else:
        print(f"\n  ⚠️ ШАГ 1 ПРОПУЩЕН: RAG требует GEMINI_API_KEY для эмбеддингов")

    # ─── ШАГ 2: Safety Tables (no Gemini) ───
    def seed_safety():
        from app.scripts.seed_safety_tables import main as safety_main
        safety_main()

    run_step(2, "Safety Tables (vitamin + drug + ingredients)", seed_safety)

    # ─── ШАГ 3: Drinks (no Gemini) ───
    def seed_drinks():
        from app.scripts.seed_drinks import main as drinks_main
        drinks_main()

    run_step(3, "Drinks Library (55 напитков)", seed_drinks)

    # ─── ШАГ 4: Workouts (no Gemini) ───
    def seed_workouts():
        from app.scripts.seed_workouts import main as workouts_main
        workouts_main()

    run_step(4, "Workouts Library (36 программ)", seed_workouts)

    # ─── ШАГ 5: Grocery Prices (no Gemini) ───
    def seed_prices():
        from app.scripts.seed_grocery_prices import main as prices_main
        prices_main()

    run_step(5, "Grocery Prices (47 цен)", seed_prices)

    # ─── ШАГ 6: Mass Meals (requires Gemini) ───
    if gemini_key:
        print(f"\n{'='*55}")
        print(f"  ШАГ 6: Meals Library (~600 рецептов)")
        print(f"  ⚠️  Этот шаг занимает 30-60 минут и стоит ~$2-6")
        print(f"  ⚠️  Запусти отдельно: python -m app.scripts.seed_meals_mass")
        print(f"{'='*55}")
    else:
        print(f"\n  ⚠️ ШАГ 6 ПРОПУЩЕН: Meals требует GEMINI_API_KEY")

    # ─── ИТОГ ───
    print(f"\n{'#'*55}")
    print(f"# SEED COMPLETE!")
    print(f"#")

    from app.db import SessionLocal
    db = SessionLocal()
    try:
        from app.models.safety_tables import VitaminInteraction, DrugFoodInteraction, IngredientReference
        from app.models.recipe_cache import MealCache
        from app.models.workout_cache import WorkoutCache
        from app.models.drink_cache import DrinkCache
        from app.models.grocery_price import GroceryPrice
        from app.models.knowledge_base import KnowledgeChunk

        counts = {
            "knowledge_chunks": db.query(KnowledgeChunk).count(),
            "vitamin_interactions": db.query(VitaminInteraction).count(),
            "drug_food_interactions": db.query(DrugFoodInteraction).count(),
            "ingredients_reference": db.query(IngredientReference).count(),
            "drinks_library": db.query(DrinkCache).count(),
            "workouts_library": db.query(WorkoutCache).count(),
            "grocery_prices": db.query(GroceryPrice).count(),
            "meals_library": db.query(MealCache).count(),
        }
        for name, count in counts.items():
            status = "✅" if count > 0 else "🔴"
            print(f"#   {status} {name}: {count}")
    except Exception as e:
        print(f"#   ⚠️ Не удалось прочитать счётчики: {e}")
    finally:
        db.close()

    print(f"#")
    print(f"{'#'*55}")


if __name__ == "__main__":
    main()
