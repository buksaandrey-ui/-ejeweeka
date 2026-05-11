"""
Deterministic safety tables for ejeweeka.
These tables contain critical medical/nutritional data that MUST NOT
be delegated to LLM generation — they are injected into prompts as
hard rules and used for post-generation validation.

Tables:
  - vitamin_interactions: Ca+Fe conflict, D3+fat requirement, etc.
  - drug_food_interactions: Warfarin+VitK, Metformin+alcohol, etc.
  - ingredients_reference: USDA-like macronutrient reference per 100g
"""

from sqlalchemy import Column, Integer, String, Float, Boolean, Text
from app.db import Base


class VitaminInteraction(Base):
    """Deterministic rules for vitamin/supplement conflicts and synergies."""
    __tablename__ = "vitamin_interactions"

    id = Column(Integer, primary_key=True, index=True)

    # Substance A (e.g. "Кальций", "Витамин C")
    substance_a = Column(String(100), nullable=False, index=True)

    # Substance B (e.g. "Железо", "Витамин B12")
    substance_b = Column(String(100), nullable=False, index=True)

    # Type: 'conflict' | 'synergy' | 'timing'
    interaction_type = Column(String(20), nullable=False, default='conflict')

    # Severity: 'critical' | 'moderate' | 'info'
    severity = Column(String(20), nullable=False, default='moderate')

    # Rule text injected into prompt (Russian)
    rule_text = Column(Text, nullable=False)

    # Minimum hours to separate intake (0 if synergy)
    separation_hours = Column(Float, default=0)

    # Whether this interaction requires food context
    requires_food = Column(Boolean, default=False)


class DrugFoodInteraction(Base):
    """Deterministic drug-food interaction rules. Replaces hardcoded DRUG_FOOD_RULES dict."""
    __tablename__ = "drug_food_interactions"

    id = Column(Integer, primary_key=True, index=True)

    # Drug keyword for matching (lowercase): "метформин", "варфарин", etc.
    drug_keyword = Column(String(100), nullable=False, index=True)

    # Full drug name for display
    drug_name = Column(String(255), nullable=False)

    # Severity: 'critical' | 'moderate' | 'info'
    severity = Column(String(20), nullable=False, default='critical')

    # Foods to AVOID (comma-separated or JSON)
    foods_avoid = Column(Text, nullable=True)

    # Foods to INCLUDE (for compensation)
    foods_include = Column(Text, nullable=True)

    # Rule text injected into prompt (Russian)
    rule_text = Column(Text, nullable=False)

    # Category for grouping: 'anticoagulant', 'thyroid', 'statin', 'ace_inhibitor', etc.
    category = Column(String(50), nullable=True)


class IngredientReference(Base):
    """
    USDA-like macronutrient reference table.
    Used for post-LLM validation of generated recipes.
    Values per 100g of raw product.
    """
    __tablename__ = "ingredients_reference"

    id = Column(Integer, primary_key=True, index=True)

    # Product name in Russian (canonical form)
    name_ru = Column(String(255), nullable=False, index=True)

    # Optional English name for cross-reference
    name_en = Column(String(255), nullable=True)

    # Macros per 100g
    calories = Column(Float, nullable=False)
    protein = Column(Float, nullable=False)
    fat = Column(Float, nullable=False)
    carbs = Column(Float, nullable=False)
    fiber = Column(Float, nullable=False, default=0)

    # Category for filtering: 'мясо', 'рыба', 'овощи', 'крупы', etc.
    category = Column(String(50), nullable=True, index=True)

    # Allergen tags: "глютен", "лактоза", "орехи"
    allergen_tags = Column(String(500), nullable=True)

    # Is this a common product? (for budget filtering)
    is_budget_friendly = Column(Boolean, default=True)
