from django.shortcuts import render
from rest_framework.decorators import api_view
from rest_framework.response import Response
import google.genai as genai
import os
from dotenv import load_dotenv

# Load the API key from the .env file
load_dotenv()

@api_view(['POST'])
def summarize_text(request):
    # 1. Get the text from the request (sent by Flutter later)
    user_text = request.data.get('text')
    
    if not user_text:
        return Response({"error": "No text provided"}, status=400)

    try:
        # 2. Initialize client with API key
        api_key = os.getenv("GEMINI_API_KEY")
        if not api_key:
            return Response({"error": "GEMINI_API_KEY not configured"}, status=500)
        
        client = genai.Client(api_key=api_key)
        
        # 3. Create a prompt
        prompt = f"Summarize the following study notes into 3 concise bullet points:\n\n{user_text}"

        # 4. Generate Content using the Gemini 2.5 Flash model
        response = client.models.generate_content(
            model='gemini-2.5-flash',
            contents=prompt
        )
        
        # 5. Return the result as JSON
        return Response({
            "summary": response.text,
            "original_length": len(user_text)
        })

    except Exception as e:
        return Response({"error": str(e)}, status=500)