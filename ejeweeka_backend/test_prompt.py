import asyncio
import os
import google.generativeai as genai
from dotenv import load_dotenv

load_dotenv(override=True)
api_key = os.getenv("GEMINI_API_KEY")
if not api_key:
    print("NO API KEY FOUND!")
    exit(1)

genai.configure(api_key=api_key)
client = genai.GenerativeModel('gemini-2.5-flash')

from app.scripts.seed_meals_wave2 import build_prompt

async def main():
    prompt = build_prompt("Завтрак", ["Гастрит"], [], "Средний", "Похудение")
    print("PROMPT:")
    print(prompt)
    
    print("\nGENERATING...")
    response = await asyncio.to_thread(
        client.generate_content,
        contents=prompt
    )
    print("\nRESULT:")
    print(response.text)

if __name__ == "__main__":
    asyncio.run(main())
