from dotenv import load_dotenv
load_dotenv()

from app.db import SessionLocal
from app.services.rag_engine import add_knowledge_chunk, search_knowledge

def run_test():
    db = SessionLocal()
    
    print("🧹 Очистка старых данных перед тестом (для чистоты эксперимента)...")
    from app.models.knowledge_base import KnowledgeChunk
    db.query(KnowledgeChunk).delete()
    db.commit()

    print("\n🧠 1. Загружаем медицинские выдержки (Генерируем эмбеддинги Gemini)...")
    chunks_to_add = [
        {
            "doctor": "Д-р Вялов",
            "spec": "Гастроэнтеролог",
            "topic": "Железо и кофе",
            "content": "Запомните: железо с кофе — деньги на ветер. Танины в кофе блокируют всасывание железа почти на 80%. Делайте перерыв минимум 2 часа."
        },
        {
            "doctor": "Д-р Иванова",
            "spec": "Эндокринолог",
            "topic": "Усвоение витамина D",
            "content": "Витамин D является жирорастворимым. Пить его натощак со стаканом воды почти бессмысленно. Обязательно совмещайте прием с жирной пищей (например, яйцо, масло, авокадо)."
        },
        {
            "doctor": "Д-р Смирнов",
            "spec": "Реабилитолог",
            "topic": "Вода утром",
            "content": "Стакан теплой воды с утра запускает перистальтику кишечника и активизирует желчный пузырь после сна."
        }
    ]

    for item in chunks_to_add:
        # Это вызовет Gemini API, переведет текст в вектор [0.12, -0.04, ...] и запишет в Postgres
        add_knowledge_chunk(db, item["doctor"], item["spec"], item["topic"], item["content"])
        print(f"✅ Добавлено: {item['topic']}")
        
    print("\n🔍 2. Проверяем Семантический поиск!")
    
    # 2 совершенно нейронных запроса "своими словами", чтобы показать, что это ищет СМЫСЛ, а не слова.
    queries = [
        "Можно ли запить капсулу железа утренним эспрессо?",
        "С чем нужно съесть витамин Д, чтобы он сработал?"
    ]
    
    for q in queries:
        print(f"\n❓ Вопрос от системы: '{q}'")
        results = search_knowledge(db, q, limit=1)
        for r in results:
            print(f"👉 Нашли ИИ-ответ от {r.doctor_name} ({r.specialization}):")
            print(f"   «{r.content}»")

if __name__ == "__main__":
    run_test()
