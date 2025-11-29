import google.generativeai as genai
import os
from dotenv import load_dotenv

# Load the API Key
load_dotenv()
api_key = os.getenv("GEMINI_API_KEY")

if not api_key:
    print("❌ Error: API Key not found in .env file.")
else:
    print(f"✅ Found API Key: {api_key[:5]}... (Hidden)")
    
    try:
        genai.configure(api_key=api_key)
        print("\n🔍 Listing available models for this key...")
        
        found_any = False
        for m in genai.list_models():
            # Only show models that can generate text (not image/embedding models)
            if 'generateContent' in m.supported_generation_methods:
                print(f" - {m.name}")
                found_any = True
        
        if not found_any:
            print("\n⚠️ No text generation models found. Check your Google AI Studio account settings.")
            
    except Exception as e:
        print(f"\n❌ Connection Error: {e}")