import "https://deno.land/x/xhr@0.3.1/mod.ts";
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

/**
 * AIDiet Stateless AI Engine (MVP Compiler Mode)
 * Architecture: Zero-Knowledge & Evidence-Based
 * 
 * Временно (до интеграции полного pgvector RAG) эта функция использует 
 * максимально строгий системный промпт, заставляющий Gemini работать в рамках 
 * доказательной медицины, опираясь на весь объем данных из онбординга.
 */

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const { profile } = await req.json();

    if (!profile) {
      throw new Error('Profile is required in request body');
    }

    // Prepare Detailed JSON Context
    const userContext = JSON.stringify({
      anthropometry: {
        age: profile.age,
        gender: profile.gender,
        weight_kg: profile.weight,
        height_cm: profile.height,
        activity_level: profile.activity_level,
        goal: profile.goal
      },
      health: {
        symptoms_gi: profile.symptoms || "Нет",
        chronic_conditions: profile.chronic_conditions || "Нет",
        diabetes_details: profile.diabetes_details || "Нет",
        thyroid_details: profile.thyroid_details || "Нет",
        womens_health: profile.womens_health || "Нет",
        allergies: profile.has_allergies ? profile.allergies : "Нет",
        medications: profile.takes_medications ? profile.medications_text : "Не принимает"
      },
      dietary_preferences: {
        restrictions: profile.diet_restrictions || "Нет",
        liked_foods: profile.liked_foods || "Нет",
        disliked_foods: profile.disliked_foods || "Нет",
        excluded_meal_types: profile.excluded_meal_types || "Нет"
      },
      lifestyle: {
        budget: profile.budget_level || "Средний",
        cooking_time: profile.cooking_time || "Готов(а) готовить 1 раз в день",
        fasting_status: profile.fasting_status || "Нет",
        meal_pattern: profile.meal_pattern || "3 приёма",
        country: profile.user_country || "Не указана"
      }
    }, null, 2);

    const systemPrompt = `
Ты — система компиляции персонального плана питания AIDiet.

ВАЖНОЕ ПРАВИЛО АРХИТЕКТУРЫ:
1. МЕДИЦИНСКАЯ БАЗА: Медицинские принципы, структура питания, запрещенные продукты, витамины и оценка совместимости с лекарствами — строятся СТРОГО на основе доказательной медицины (как если бы ты извлекал их из базы знаний 4000+ лекций врачей). НЕ выдумывай медицинские факты!
2. КУЛИНАРНАЯ СВОБОДА: Конкретные рецепты блюд, граммовки ингредиентов и варианты приготовления — ты берёшь из своих широких кулинарных сведений (из открытых источников), ГАРАНТИРУЯ, что они не нарушают выставленные медицинские ограничения профиля.

ПРОФИЛЬ ПОЛЬЗОВАТЕЛЯ:
${userContext}

КРИТИЧЕСКИЕ ПРАВИЛА КОМПИЛЯЦИИ:
1. АЛЛЕРГИИ И ОГРАНИЧЕНИЯ: Строгий запрет на включение аллергенов и продуктов из списка ограничений или нелюбимых продуктов.
2. СОВМЕСТИМОСТЬ С ЛЕКАРСТВАМИ: Учти принимаемые лекарства. Избегай продуктов, снижающих их эффективность (например, грейпфрут со статинами, кальций с омепразолом и т.д.).
3. МИКРОБИОМ: Если в симптомах указаны проблемы с ЖКТ (вздутие, нестабильный стул, диабет), обязательно добавь ферментированные продукты (кефир, кимчи и др. по переносимости).
4. БЮДЖЕТ И ЛОКАЦИЯ: Учитывай страну и уровень бюджета пользователя. Продукты должны быть реальны для покупки.
5. РАСПИСАНИЕ: Учитывай паттерн приемов пищи и интервальное голодание.

ЗАДАЧА:
Сгенерируй строго типизированный JSON-план питания на 1 день. Распределение БЖУ: ~30% белки, ~30% жиры, ~40% углеводы.

Ответь ИСКЛЮЧИТЕЛЬНО в формате JSON:
{
  "day_1": [
    {
      "meal_type": "breakfast",
      "name": "Название блюда",
      "calories": 400,
      "protein": 25,
      "fat": 15,
      "carbs": 40,
      "prep_time_min": 15,
      "image_url": "https://images.unsplash.com/photo-XXX (Оставь пустым, если не знаешь)",
      "medical_rationale": "Краткое обоснование: почему это блюдо с его ингредиентами (открытый источник) безопасно и полезно для данного пациента согласно медицинским правилам.",
      "ingredients": [
        { "name": "Куриная грудка", "amount": "150 г" },
        { "name": "Киноа (сухое)", "amount": "50 г" }
      ],
      "steps": [
        "Промой киноа под холодной водой. Залей 100 мл воды, доведи до кипения и вари на медленном огне.",
        "Нарежь куриную грудку кубиками. Обжарь 8-10 минут без масла."
      ]
    },
    // Добавь lunch, dinner (и перекусы, если запрашивал пользователь)
  ]
}
`;

    const geminiApiKey = Deno.env.get('GEMINI_API_KEY');
    if (!geminiApiKey) throw new Error('GEMINI_API_KEY is not set');

    const geminiRes = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${geminiApiKey}`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        contents: [{ role: "user", parts: [{ text: systemPrompt }] }],
        generationConfig: { response_mime_type: "application/json", temperature: 0.2 }
      })
    });

    if (!geminiRes.ok) throw new Error(`Gemini API Error: ${await geminiRes.text()}`);

    const geminiData = await geminiRes.json();
    const aiText = geminiData.candidates[0].content.parts[0].text;
    const parsedPlan = JSON.parse(aiText);

    return new Response(JSON.stringify(parsedPlan), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
