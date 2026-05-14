"""
Seed: vitamin_interactions — deterministic rules for vitamin/supplement conflicts and synergies.
These rules are injected into LLM prompts as hard constraints and used for post-generation validation.
Run: cd ejeweeka_backend && python -m scripts.seed_vitamin_interactions
"""

import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from app.db import engine, Base, SessionLocal
from app.models.safety_tables import VitaminInteraction
from sqlalchemy import text

RULES = [
    # ═══════════════════════════════════════════════════════════════
    # КОНФЛИКТЫ (conflict) — приём одновременно снижает усвоение
    # ═══════════════════════════════════════════════════════════════
    {
        "substance_a": "Кальций", "substance_b": "Железо",
        "interaction_type": "conflict", "severity": "critical",
        "rule_text": "Кальций блокирует всасывание железа в кишечнике. Разнести приём минимум на 2-3 часа. Кальций — вечер, железо — утро натощак.",
        "separation_hours": 3.0, "requires_food": False,
    },
    {
        "substance_a": "Кальций", "substance_b": "Цинк",
        "interaction_type": "conflict", "severity": "moderate",
        "rule_text": "Кальций конкурирует с цинком за транспортные белки. Разнести на 2 часа.",
        "separation_hours": 2.0, "requires_food": False,
    },
    {
        "substance_a": "Кальций", "substance_b": "Магний",
        "interaction_type": "conflict", "severity": "moderate",
        "rule_text": "Высокие дозы кальция снижают усвоение магния. Принимать в разное время суток (кальций утром, магний вечером).",
        "separation_hours": 4.0, "requires_food": False,
    },
    {
        "substance_a": "Железо", "substance_b": "Цинк",
        "interaction_type": "conflict", "severity": "moderate",
        "rule_text": "Железо и цинк конкурируют за общие транспортёры DMT-1. Разнести приём на 2 часа.",
        "separation_hours": 2.0, "requires_food": False,
    },
    {
        "substance_a": "Железо", "substance_b": "Витамин E",
        "interaction_type": "conflict", "severity": "moderate",
        "rule_text": "Неорганическое железо разрушает витамин E. Разнести приём на 6-8 часов.",
        "separation_hours": 6.0, "requires_food": False,
    },
    {
        "substance_a": "Витамин B12", "substance_b": "Витамин C",
        "interaction_type": "conflict", "severity": "moderate",
        "rule_text": "Высокие дозы витамина C (>500мг) могут разрушать B12. Разнести приём на 2 часа.",
        "separation_hours": 2.0, "requires_food": False,
    },
    {
        "substance_a": "Витамин B6", "substance_b": "Леводопа",
        "interaction_type": "conflict", "severity": "critical",
        "rule_text": "Витамин B6 снижает эффективность леводопы (лекарство при Паркинсоне). ЗАПРЕЩЕНО без консультации врача.",
        "separation_hours": 0, "requires_food": False,
    },
    {
        "substance_a": "Витамин K", "substance_b": "Варфарин",
        "interaction_type": "conflict", "severity": "critical",
        "rule_text": "Витамин K нейтрализует действие варфарина (антикоагулянт). Стабильное потребление витамина K обязательно при терапии варфарином. Резкое увеличение/уменьшение ЗАПРЕЩЕНО.",
        "separation_hours": 0, "requires_food": True,
    },
    {
        "substance_a": "Медь", "substance_b": "Цинк",
        "interaction_type": "conflict", "severity": "moderate",
        "rule_text": "Высокие дозы цинка (>40мг/день) вызывают дефицит меди. При длительном приёме цинка добавить 1-2мг меди.",
        "separation_hours": 2.0, "requires_food": False,
    },
    {
        "substance_a": "Витамин A", "substance_b": "Витамин A (ретинол)",
        "interaction_type": "conflict", "severity": "critical",
        "rule_text": "НЕ комбинировать два источника ретинола (например, рыбий жир + мультивитамин с ретинолом). Гипервитаминоз A токсичен для печени. Максимум 3000 МЕ/день.",
        "separation_hours": 0, "requires_food": False,
    },
    {
        "substance_a": "Кальций", "substance_b": "Тироксин (Л-тироксин)",
        "interaction_type": "conflict", "severity": "critical",
        "rule_text": "Кальций блокирует всасывание тироксина. Принимать тироксин СТРОГО натощак за 30-60 мин до еды. Кальций — не ранее чем через 4 часа.",
        "separation_hours": 4.0, "requires_food": False,
    },
    {
        "substance_a": "Железо", "substance_b": "Тироксин (Л-тироксин)",
        "interaction_type": "conflict", "severity": "critical",
        "rule_text": "Железо снижает всасывание тироксина. Разнести приём на 4 часа.",
        "separation_hours": 4.0, "requires_food": False,
    },
    {
        "substance_a": "Кальций", "substance_b": "Бисфосфонаты",
        "interaction_type": "conflict", "severity": "critical",
        "rule_text": "Кальций нейтрализует бисфосфонаты (препараты от остеопороза). Принимать бисфосфонаты строго натощак, кальций — через 2+ часа.",
        "separation_hours": 2.0, "requires_food": False,
    },
    {
        "substance_a": "Кальций", "substance_b": "Антибиотики (тетрациклины)",
        "interaction_type": "conflict", "severity": "critical",
        "rule_text": "Кальций образует нерастворимые комплексы с тетрациклинами и фторхинолонами, делая их неэффективными. Разнести на 2-3 часа.",
        "separation_hours": 3.0, "requires_food": False,
    },
    {
        "substance_a": "Магний", "substance_b": "Антибиотики (фторхинолоны)",
        "interaction_type": "conflict", "severity": "critical",
        "rule_text": "Магний и алюминий связывают фторхинолоны. Разнести приём на 2 часа до или 6 часов после антибиотика.",
        "separation_hours": 6.0, "requires_food": False,
    },
    {
        "substance_a": "Фолиевая кислота", "substance_b": "Метотрексат",
        "interaction_type": "conflict", "severity": "critical",
        "rule_text": "Фолиевая кислота снижает эффективность метотрексата. При терапии метотрексатом фолат назначается СТРОГО по схеме врача.",
        "separation_hours": 0, "requires_food": False,
    },
    {
        "substance_a": "Витамин E", "substance_b": "Антикоагулянты",
        "interaction_type": "conflict", "severity": "moderate",
        "rule_text": "Высокие дозы витамина E (>400 МЕ) усиливают антикоагулянтный эффект. Риск кровотечений. Ограничить до 200 МЕ/день.",
        "separation_hours": 0, "requires_food": False,
    },
    {
        "substance_a": "Зверобой", "substance_b": "Антидепрессанты (СИОЗС)",
        "interaction_type": "conflict", "severity": "critical",
        "rule_text": "Зверобой + СИОЗС = риск серотонинового синдрома (смертельно опасно). ЗАПРЕЩЕНО совмещать.",
        "separation_hours": 0, "requires_food": False,
    },
    {
        "substance_a": "Зверобой", "substance_b": "Оральные контрацептивы",
        "interaction_type": "conflict", "severity": "critical",
        "rule_text": "Зверобой ускоряет метаболизм контрацептивов через CYP3A4, снижая их эффективность. ЗАПРЕЩЕНО совмещать.",
        "separation_hours": 0, "requires_food": False,
    },
    {
        "substance_a": "Грейпфрут", "substance_b": "Статины",
        "interaction_type": "conflict", "severity": "critical",
        "rule_text": "Грейпфрут блокирует фермент CYP3A4, резко повышая концентрацию статинов в крови. Риск рабдомиолиза. ИСКЛЮЧИТЬ грейпфрут и помело из рациона.",
        "separation_hours": 0, "requires_food": True,
    },

    # ═══════════════════════════════════════════════════════════════
    # СИНЕРГИИ (synergy) — усиливают друг друга
    # ═══════════════════════════════════════════════════════════════
    {
        "substance_a": "Витамин D3", "substance_b": "Витамин K2",
        "interaction_type": "synergy", "severity": "info",
        "rule_text": "D3 усиливает всасывание кальция, K2 направляет кальций в кости (а не в сосуды). Идеальная пара. Принимать вместе с жирной пищей.",
        "separation_hours": 0, "requires_food": True,
    },
    {
        "substance_a": "Витамин D3", "substance_b": "Кальций",
        "interaction_type": "synergy", "severity": "info",
        "rule_text": "Витамин D3 критически необходим для усвоения кальция в кишечнике. Без D3 усваивается только 10-15% кальция.",
        "separation_hours": 0, "requires_food": True,
    },
    {
        "substance_a": "Железо", "substance_b": "Витамин C",
        "interaction_type": "synergy", "severity": "info",
        "rule_text": "Витамин C (50-100мг) увеличивает усвоение негемового железа в 2-3 раза. Принимать железо с апельсиновым соком или аскорбинкой.",
        "separation_hours": 0, "requires_food": False,
    },
    {
        "substance_a": "Магний", "substance_b": "Витамин B6",
        "interaction_type": "synergy", "severity": "info",
        "rule_text": "B6 улучшает транспорт магния в клетки. Форма 'магний B6' (пиридоксин + цитрат магния) — оптимальна.",
        "separation_hours": 0, "requires_food": False,
    },
    {
        "substance_a": "Витамин D3", "substance_b": "Магний",
        "interaction_type": "synergy", "severity": "info",
        "rule_text": "Магний необходим для активации витамина D (конвертация в активную форму 1,25(OH)₂D). При дефиците магния D3 неэффективен.",
        "separation_hours": 0, "requires_food": False,
    },
    {
        "substance_a": "Омега-3", "substance_b": "Витамин E",
        "interaction_type": "synergy", "severity": "info",
        "rule_text": "Витамин E защищает Омега-3 жирные кислоты от окисления. Принимать вместе с жирной пищей.",
        "separation_hours": 0, "requires_food": True,
    },
    {
        "substance_a": "Куркумин", "substance_b": "Пиперин (чёрный перец)",
        "interaction_type": "synergy", "severity": "info",
        "rule_text": "Пиперин увеличивает биодоступность куркумина на 2000%. Всегда принимать куркуму с щепоткой чёрного перца.",
        "separation_hours": 0, "requires_food": True,
    },
    {
        "substance_a": "Цинк", "substance_b": "Витамин A",
        "interaction_type": "synergy", "severity": "info",
        "rule_text": "Цинк необходим для транспорта витамина A из печени. При дефиците цинка ретинол не работает.",
        "separation_hours": 0, "requires_food": False,
    },
    {
        "substance_a": "Селен", "substance_b": "Витамин E",
        "interaction_type": "synergy", "severity": "info",
        "rule_text": "Селен и витамин E — антиоксидантная пара. Селен входит в глутатионпероксидазу, E — в мембранную защиту. Работают синергично.",
        "separation_hours": 0, "requires_food": False,
    },

    # ═══════════════════════════════════════════════════════════════
    # ТАЙМИНГ (timing) — важно когда принимать
    # ═══════════════════════════════════════════════════════════════
    {
        "substance_a": "Витамин D3", "substance_b": "Жирная пища",
        "interaction_type": "timing", "severity": "info",
        "rule_text": "D3 — жирорастворимый. Принимать ТОЛЬКО с едой, содержащей жиры (масло, орехи, авокадо). Натощак усвоение <30%.",
        "separation_hours": 0, "requires_food": True,
    },
    {
        "substance_a": "Железо", "substance_b": "Натощак",
        "interaction_type": "timing", "severity": "info",
        "rule_text": "Железо лучше всего усваивается натощак (за 1 час до еды). Но при побочных эффектах (тошнота) — можно с лёгкой пищей.",
        "separation_hours": 0, "requires_food": False,
    },
    {
        "substance_a": "Магний", "substance_b": "Вечерний приём",
        "interaction_type": "timing", "severity": "info",
        "rule_text": "Магний оказывает лёгкое седативное действие. Оптимально принимать вечером, за 1-2 часа до сна. Улучшает качество сна.",
        "separation_hours": 0, "requires_food": False,
    },
    {
        "substance_a": "Витамины группы B", "substance_b": "Утренний приём",
        "interaction_type": "timing", "severity": "info",
        "rule_text": "Витамины B (особенно B6, B12) тонизируют. Принимать УТРОМ с завтраком. Вечерний приём может нарушить засыпание.",
        "separation_hours": 0, "requires_food": True,
    },
    {
        "substance_a": "Пробиотики", "substance_b": "Антибиотики",
        "interaction_type": "timing", "severity": "moderate",
        "rule_text": "При приёме антибиотиков пробиотики принимать через 2-3 часа ПОСЛЕ антибиотика. Продолжать 2 недели после окончания курса.",
        "separation_hours": 3.0, "requires_food": False,
    },
    {
        "substance_a": "Омега-3", "substance_b": "Жирная пища",
        "interaction_type": "timing", "severity": "info",
        "rule_text": "Омега-3 жирорастворимы. Принимать с основным приёмом пищи (обед/ужин). Утренний приём натощак вызывает рыбную отрыжку.",
        "separation_hours": 0, "requires_food": True,
    },
    {
        "substance_a": "Коэнзим Q10", "substance_b": "Жирная пища",
        "interaction_type": "timing", "severity": "info",
        "rule_text": "CoQ10 — жирорастворимый. Принимать с едой, содержащей жиры. Убихинол (активная форма) — предпочтительнее убихинона.",
        "separation_hours": 0, "requires_food": True,
    },
]


def seed():
    Base.metadata.create_all(bind=engine, tables=[VitaminInteraction.__table__])
    db = SessionLocal()

    existing = db.query(VitaminInteraction).count()
    if existing > 0:
        print(f"⚠️  Таблица vitamin_interactions уже содержит {existing} записей. Очищаем...")
        db.execute(text("TRUNCATE TABLE vitamin_interactions RESTART IDENTITY"))
        db.commit()

    added = 0
    for r in RULES:
        vi = VitaminInteraction(
            substance_a=r["substance_a"],
            substance_b=r["substance_b"],
            interaction_type=r["interaction_type"],
            severity=r["severity"],
            rule_text=r["rule_text"],
            separation_hours=r["separation_hours"],
            requires_food=r["requires_food"],
        )
        db.add(vi)
        added += 1

    db.commit()
    db.close()
    print(f"✅ Добавлено {added} правил взаимодействия витаминов/добавок.")


if __name__ == "__main__":
    seed()
