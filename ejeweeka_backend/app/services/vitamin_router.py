"""
Geo-Vitamin & Diet Supplement Engine (Rules Engine)
Определяет потребности в витаминах и БАДах на основе региона проживания и диетических ограничений,
БЕЗ использования генеративного ИИ.
"""

from typing import List, Dict

# Гео-климатические зоны
HIGH_SUN_REGIONS = {"UAE", "ES", "BR", "EG", "AU", "SA", "QA"} # ОАЭ, Испания, Бразилия, Египет, Австралия, Саудовская Аравия, Катар
OCEANIC_REGIONS = {"NO", "JP", "IS", "PT", "CL"} # Норвегия, Япония, Исландия, Португалия, Чили
LOW_SUN_REGIONS = {"RU", "FI", "SE", "NO", "CA", "GB"} # Россия, Финляндия, Швеция, Канада, Великобритания

class VitaminRouter:
    
    @staticmethod
    def get_geo_vitamin_rules(country_code: str) -> Dict[str, str]:
        """Возвращает правила для витаминов на основе страны."""
        rules = {"d3": "standard", "omega3": "standard"}
        
        country_code = country_code.upper()
        
        if country_code in HIGH_SUN_REGIONS:
            rules["d3"] = "exclude" # Слишком много солнца
        elif country_code in LOW_SUN_REGIONS:
            rules["d3"] = "force"   # Дефицит солнца зимой
            
        if country_code in OCEANIC_REGIONS:
            rules["omega3"] = "reduce" # Много рыбы в рационе
            
        return rules

    @staticmethod
    def get_diet_supplements(restrictions: List[str]) -> List[Dict[str, str]]:
        """Возвращает обязательные добавки на основе диеты/болезней."""
        supplements = []
        
        lower_restrictions = [r.lower() for r in restrictions]
        
        if "веган" in lower_restrictions or "веганство" in lower_restrictions:
            supplements.append({"name": "Витамин B12", "reason": "Обязателен при веганстве (отсутствует в растительной пище)."})
            supplements.append({"name": "Железо", "reason": "Растительное железо усваивается хуже животного."})
            
        if "безлактозная" in lower_restrictions or "лактоза" in lower_restrictions:
            supplements.append({"name": "Кальций", "reason": "Рекомендован при исключении молочных продуктов."})
            
        if "пескарианство" in lower_restrictions:
            # Омега-3 не нужна, так как человек ест рыбу
            pass
            
        return supplements

    @staticmethod
    def generate_recommendation_text(country_code: str, restrictions: List[str]) -> str:
        """Генерирует финальный текст для PromptAssembler или напрямую для UI."""
        geo_rules = VitaminRouter.get_geo_vitamin_rules(country_code)
        diet_sups = VitaminRouter.get_diet_supplements(restrictions)
        
        instructions = []
        
        # Инъекция гео-правил
        if geo_rules["d3"] == "exclude":
            instructions.append(f"- В регионе {country_code} высокий индекс инсоляции. НЕ рекомендуйте добавку Витамин D3 (если только по анализам).")
        elif geo_rules["d3"] == "force":
            instructions.append(f"- В регионе {country_code} низкий индекс инсоляции. Обязательно порекомендуйте профилактическую дозу Витамина D3.")
            
        if geo_rules["omega3"] == "reduce":
            instructions.append(f"- Регион {country_code} имеет морской климат (много рыбы). Снизьте приоритет добавки Омега-3.")

        # Инъекция диетических правил
        for sup in diet_sups:
            instructions.append(f"- Обязательно назначьте {sup['name']}. Обоснование: {sup['reason']}")
            
        if not instructions:
            return "- Стандартный протокол БАД."
            
        return "\n".join(instructions)
