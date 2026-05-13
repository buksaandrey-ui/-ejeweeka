import os
from google import genai
from dotenv import load_dotenv

load_dotenv()
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY").strip('"\'')
print(f"Key loaded: {GEMINI_API_KEY[:5]}... len: {len(GEMINI_API_KEY)}")

try:
    client = genai.Client(api_key=GEMINI_API_KEY)
    response = client.models.generate_content(
        model='gemini-2.5-flash',
        contents='Привет'
    )
    print("Success:", response.text)
except Exception as e:
    print("Error:", e)
