import os
import asyncio
from google import genai

# Мы используем DALL-E 3 для production качества фуд-фотографии.
# Если ключа нет, возвращаем красивый fallback с Unsplash (по ключевому слову).
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")

async def generate_meal_image(meal_name: str, ingredients_text: str) -> str:
    """
    Генерирует аппетитную фотографию блюда через DALL-E 3.
    Если ключа нет, возвращает релевантную картинку с Unsplash.
    """
    if not OPENAI_API_KEY:
        # Fallback for MVP / Testing without spending tokens
        # Конвертируем русское название в английский slug для Unsplash
        query = meal_name.split()[0] if meal_name else "healthy-food"
        # Запрос к Unsplash Source API (или подобному сервису)
        return f"https://source.unsplash.com/800x600/?food,{query}"

    try:
        from openai import AsyncOpenAI
        client = AsyncOpenAI(api_key=OPENAI_API_KEY)
        
        prompt = f"Professional food photography of {meal_name}. Ingredients: {ingredients_text}. Top-down view, natural sunlight, healthy diet aesthetic, 4k, hyper-realistic, placed on a beautiful ceramic plate."
        
        response = await client.images.generate(
            model="dall-e-3",
            prompt=prompt,
            size="1024x1024",
            quality="standard",
            n=1,
        )
        return response.data[0].url
    except Exception as e:
        print(f"⚠️ Ошибка генерации фото для {meal_name}: {e}")
        return "https://source.unsplash.com/800x600/?healthy-food"
