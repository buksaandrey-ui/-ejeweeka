import os
from google import genai

client = genai.Client(api_key="AIzaSyAEY2pJk0VURXFHJiJl4CIUFl7G5bUleRg")
try:
    response = client.models.generate_content(
        model='gemini-2.5-flash',
        contents='Привет, скажи 1 слово.'
    )
    print(response.text)
except Exception as e:
    print("Error:", e)
