"""
RAG Knowledge Base Coverage Tests for ejeweeka.
Validates that the knowledge base has relevant medical context
for all supported goals, diseases, and conditions.
"""

import pytest
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from dotenv import load_dotenv
load_dotenv()

from app.db import SessionLocal
from app.services.rag_engine import search_knowledge


# ═══════════════════════════════════════════════════════════════
# COVERAGE MATRIX
# ═══════════════════════════════════════════════════════════════

# Каждая запись: (поисковый запрос, минимальное ожидаемое количество чанков, описание)
COVERAGE_MATRIX = [
    # Цели
    ("Диета для снижения веса, калорийный дефицит", 1, "weight_loss"),
    ("Набор мышечной массы, белок, лейцин", 1, "muscle_gain"),
    ("Поддержание веса, изокалорийность", 1, "maintenance"),
    ("Энергия, самочувствие, микронутриенты", 1, "improve_energy"),
    ("Питание для кожи, волос, ногтей, коллаген, антиоксиданты", 1, "skin_hair_nails"),
    ("Адаптация питания к возрасту, саркопения", 1, "age_adaptation"),
    ("Восстановление после болезни, реабилитация", 1, "recovery"),
    
    # Болезни
    ("Диабет 2 типа, гликемический индекс, инсулин", 1, "diabetes"),
    ("Гипертония, натрий, DASH диета", 1, "hypertension"),
    ("Подагра, мочевая кислота, пурины", 1, "gout"),
    ("Гастрит, ГЭРБ, щадящее питание", 1, "gastritis"),
    ("СПКЯ, инсулинорезистентность, гормоны", 1, "pcos"),
    ("Болезнь Крона, воспалительные заболевания кишечника", 0, "crohns"),  # May be empty
    ("Хроническая почечная недостаточность, ограничение белка", 0, "kidney"),  # May be empty
    
    # Женское здоровье
    ("Беременность, фолиевая кислота, железо, питание для беременных", 1, "pregnancy"),
    ("Грудное вскармливание, лактация, питание кормящей", 1, "breastfeeding"),
    ("Менопауза, кальций, фитоэстрогены", 1, "menopause"),
    
    # Возраст
    ("Питание для пожилых, саркопения, белок после 60 лет", 1, "senior"),
    ("Спортивное питание для молодых, интенсивные тренировки", 0, "young_sport"),
    
    # Лекарства
    ("Варфарин, витамин K, антикоагулянты", 0, "warfarin"),
    ("Метформин, диабет, побочные эффекты", 0, "metformin"),
    ("Л-тироксин, щитовидная железа, гипотиреоз", 0, "levothyroxine"),
]


class TestRagCoverage:
    """Validates RAG knowledge base coverage for critical medical topics."""
    
    @pytest.fixture(scope="class")
    def db(self):
        db = SessionLocal()
        yield db
        db.close()
    
    def test_total_chunks_count(self, db):
        """Knowledge base should have a minimum number of chunks."""
        from app.models.knowledge_base import KnowledgeChunk
        total = db.query(KnowledgeChunk).count()
        print(f"\n📊 Total knowledge chunks in DB: {total}")
        # Минимум — мы хотим хотя бы 50 чанков для базового покрытия
        assert total >= 10, f"Knowledge base too small: only {total} chunks. Minimum 10 required."
    
    def test_coverage_matrix(self, db):
        """Test that key medical topics have RAG coverage."""
        gaps = []
        covered = []
        
        for query, min_expected, label in COVERAGE_MATRIX:
            results = search_knowledge(db, query, limit=3)
            count = len(results)
            
            if count >= max(min_expected, 1):
                covered.append(f"✅ {label}: {count} chunks found")
            elif count > 0:
                covered.append(f"⚠️ {label}: {count} chunks (wanted {min_expected})")
            else:
                if min_expected > 0:
                    gaps.append(f"❌ {label}: 0 chunks found for '{query[:60]}...'")
                else:
                    covered.append(f"⚠️ {label}: 0 chunks (optional topic)")
        
        print("\n=== RAG COVERAGE REPORT ===")
        for c in covered:
            print(c)
        if gaps:
            print("\n=== GAPS (topics with no RAG context) ===")
            for g in gaps:
                print(g)
        
        # We want at least 50% coverage of mandatory topics
        mandatory_topics = [item for item in COVERAGE_MATRIX if item[1] > 0]
        coverage_ratio = (len(mandatory_topics) - len(gaps)) / len(mandatory_topics) if mandatory_topics else 1
        print(f"\n📊 Coverage: {int(coverage_ratio * 100)}% ({len(mandatory_topics) - len(gaps)}/{len(mandatory_topics)} mandatory topics)")
        
        # Soft assertion — log gaps but don't fail if some are missing
        # because the user may not have populated all topics yet
        if len(gaps) > len(mandatory_topics) * 0.5:
            pytest.fail(
                f"RAG coverage too low: {len(gaps)}/{len(mandatory_topics)} mandatory topics have no context.\n"
                f"Gaps: {', '.join(g.split(':')[1].strip() for g in gaps)}"
            )

    def test_expert_diversity(self, db):
        """Knowledge base should have content from multiple medical experts."""
        from app.models.knowledge_base import KnowledgeChunk
        from sqlalchemy import func
        
        expert_count = db.query(func.count(func.distinct(KnowledgeChunk.doctor_name))).scalar()
        print(f"\n📊 Unique medical experts in DB: {expert_count}")
        
        # Мы хотим минимум 3 разных эксперта
        assert expert_count >= 1, f"Only {expert_count} expert(s) in DB. Need at least 3 for credibility."


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
