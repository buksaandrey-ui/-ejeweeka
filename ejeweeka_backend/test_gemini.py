import os
from google import genai

client = genai.Client(api_key="AIzaSyCAahi4mtgesspBrQ7VSAqm2LU9UbeSdqg")
try:
    response = client.models.generate_content(
        model='gemini-2.5-flash',
        contents='Привет, скажи 1 слово.'
    )
    print(response.text)
except Exception as e:
    print("Error:", e)
