import os
import google.generativeai as genai
from dotenv import load_dotenv

load_dotenv()
genai.configure(api_key=os.getenv('GEMINI_API_KEY'))

try:
    models = genai.list_models()
    embed_models = [m.name for m in models if 'embedContent' in m.supported_generation_methods]
    print("SUPPORTED MODELS:", embed_models)
except Exception as e:
    print("ERROR:", str(e))
