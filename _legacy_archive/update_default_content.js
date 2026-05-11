import fs from 'fs';

const contentFile = 'landing-page/src/data/landing-content.ts';
let code = fs.readFileSync(contentFile, 'utf8');

const mainLandingObj = `{
    "titlePart1": "Архитектура вашего тела.",
    "titlePart2": "Идеально рассчитана.",
    "subtitle": "Ваша энергия, продуктивность и физическая форма больше не зависят от случайностей. Health Code объединяет питание, восстановление, тренировки и графики добавок в единый смарт-план.",
    "problemBadge": "Wellness-ядро Health Code",
    "problemTitle": "Не просто считает калории. Собирает систему.",
    "problemDesc1": "Ваш план базируется на 16 000+ экспертных материалах в базе знаний от практикующих специалистов.",
    "problemDesc2": "Мы объединили питание, витамины, сон и активность, чтобы вы не тратили время на поиск разрозненной информации.",
    "scenarios": [
        {
            "badge": "Кейс 1: Питание",
            "title": "Планирует питание",
            "problem": "Подбирает блюда под цель, режим, бюджет, ограничения и любимые продукты.",
            "solution": "Умный рацион с учётом ограничений и wellness-правил."
        },
        {
            "badge": "Кейс 2: Витамины",
            "title": "Следит за витаминами",
            "problem": "Подсказывает, когда принимать добавки, чтобы они не мешали друг другу.",
            "solution": "Совместимость лекарств и БАД в реальном времени."
        },
        {
            "badge": "Кейс 3: Фото-анализ",
            "title": "Считает еду по фото",
            "problem": "Сфотографируйте блюдо, а Health Code оценит состав и пересчитает план.",
            "solution": "Распознавание состава и КБЖУ по фото за доли секунды."
        }
    ],
    "bentoFeatures": [
        {
            "id": "family",
            "title": "Планирует питание",
            "description": "Подбирает блюда под цель, бюджет и вкусы."
        },
        {
            "id": "micro",
            "title": "Список покупок",
            "description": "Группирует продукты по отделам."
        },
        {
            "id": "privacy",
            "title": "Следит за витаминами",
            "description": "Исключает конфликты добавок."
        },
        {
            "id": "recalc",
            "title": "Корректирует день",
            "description": "Учитывает активность и перекусы на лету."
        },
        {
            "id": "medical",
            "title": "Фото-анализ",
            "description": "Считает КБЖУ по фотографии еды."
        },
        {
            "id": "eco",
            "title": "Локальное хранение",
            "description": "Zero-Knowledge принцип безопасности."
        }
    ],
    "ctaText": "Активировать 3 дня Gold"
}`;

code = code.replace(
  /'default': \{[\s\S]*?'sweet-tooth':/,
  `'default': ${mainLandingObj},
  'main-landing': ${mainLandingObj},
  'sweet-tooth':`
);

fs.writeFileSync(contentFile, code);
