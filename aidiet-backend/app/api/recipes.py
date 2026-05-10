from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel, Field
import hashlib
from google import genai
import os
from dotenv import load_dotenv
from sqlalchemy.orm import Session
from app.db import get_db
from app.models.recipe_cache import RecipeImageCache

load_dotenv()
router = APIRouter()

class RecipeImageRequest(BaseModel):
    title: str = Field(description="Название блюда, например: Греческий салат")
    ingredients: list[str] = Field(description="Список реальных ингредиентов без запрещенки")
    excluded_allergens: list[str] = Field(default=[], description="Список аллергенов для исключения из визуала")

@router.post("/image")
def get_or_generate_recipe_image(req: RecipeImageRequest, db: Session = Depends(get_db)):
    """
    Получает изображение для рецепта:
    1. Ищет в БД закешированную версию по хешу ингредиентов.
    2. Если нет в кеше — генерирует с помощью Imagen 4, сохраняет и возвращает.
    """
    # 1. Hashing
    sorted_ingredients = sorted([i.strip().lower() for i in req.ingredients])
    hash_str = ",".join(sorted_ingredients)
    ingredients_hash = hashlib.md5(hash_str.encode('utf-8')).hexdigest()
    
    # 2. Check Cache
    cached = db.query(RecipeImageCache).filter(RecipeImageCache.ingredients_hash == ingredients_hash).first()
    if cached:
        print(f"📦 Возвращаем закешированное фото блюда: {ingredients_hash}")
        return {"status": "success", "image_url": cached.image_url, "cached": True}
        
    print(f"🎨 Генерируем новое фото через Imagen 4: {req.title}")
    
    # 3. Generate Image
    GEMINI_API_KEY = os.getenv('GEMINI_API_KEY')
    if not GEMINI_API_KEY:
        raise HTTPException(status_code=500, detail="GEMINI_API_KEY не установлен")
        
    client = genai.Client(api_key=GEMINI_API_KEY)
    mapped_ingredients = ', '.join(sorted_ingredients)
    
    allergen_clause = ''
    if req.excluded_allergens:
        excluded_str = ', '.join(req.excluded_allergens)
        allergen_clause = f' DO NOT show or depict: {excluded_str}.'
    
    prompt = f"Professional food photography of: {req.title}. Plated on a simple white ceramic plate. STRICTLY made only using the following ingredients: {mapped_ingredients}. DO NOT include any other visible ingredients, especially if they are not in the list.{allergen_clause} Overhead angle, natural daylight, minimal garnish, photorealistic."
    
    try:
        result = client.models.generate_images(
            model='imagen-4.0-fast-generate-001',
            prompt=prompt,
            config={
                'number_of_images': 1,
                'output_mime_type': 'image/jpeg',
                'aspect_ratio': '1:1'
            }
        )
        
        image_bytes = result.generated_images[0].image.image_bytes
        
        # Save bytes
        save_dir = os.path.join(os.path.dirname(__file__), '../../data/images')
        os.makedirs(save_dir, exist_ok=True)
        
        filename = f"{ingredients_hash}.jpg"
        filepath = os.path.join(save_dir, filename)
        
        with open(filepath, "wb") as f:
            f.write(image_bytes)
            
        image_url = f"/images/{filename}"
        
        # 4. Save to DB Cache
        new_cache = RecipeImageCache(
            ingredients_hash=ingredients_hash,
            recipe_title=req.title,
            image_url=image_url
        )
        db.add(new_cache)
        db.commit()
        
        return {"status": "success", "image_url": image_url, "cached": False}
        
    except Exception as e:
        print(f"Ошибка Imagen: {str(e)}")
        raise HTTPException(status_code=500, detail="Ошибка генерации фотографии рецепта")
