from django.shortcuts import render
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth.models import User
import google.genai as genai
import os
from dotenv import load_dotenv
from .models import Summary

# Load the API key from the .env file
load_dotenv()

@api_view(['POST'])
def register_user(request):
    """Register a new user"""
    username = request.data.get('username')
    password = request.data.get('password')
    
    if not username or not password:
        return Response({"error": "Username and password required"}, status=400)
    
    if len(password) < 6:
        return Response({"error": "Password must be at least 6 characters"}, status=400)
    
    # Check if user already exists
    if User.objects.filter(username=username).exists():
        return Response({"error": "Username already exists"}, status=400)
    
    try:
        # Create new user
        user = User.objects.create_user(username=username, password=password)
        
        # Generate JWT tokens
        refresh = RefreshToken.for_user(user)
        
        return Response({
            "message": "User registered successfully",
            "access": str(refresh.access_token),
            "refresh": str(refresh),
            "username": username
        }, status=201)
    
    except Exception as e:
        return Response({"error": str(e)}, status=500)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
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

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def save_summary(request):
    """Save a summary to the user's account"""
    original_text = request.data.get('original_text')
    summary_text = request.data.get('summary_text')
    
    if not original_text or not summary_text:
        return Response({"error": "Both original_text and summary_text are required"}, status=400)
    
    try:
        summary = Summary.objects.create(
            user=request.user,
            original_text=original_text,
            summary_text=summary_text
        )
        
        return Response({
            "message": "Summary saved successfully",
            "id": summary.id,
            "created_at": summary.created_at
        }, status=201)
    
    except Exception as e:
        return Response({"error": str(e)}, status=500)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_user_summaries(request):
    """Get all summaries for the logged-in user"""
    try:
        summaries = Summary.objects.filter(user=request.user).order_by('-created_at')
        
        data = [{
            "id": summary.id,
            "original_text": summary.original_text[:200] + "..." if len(summary.original_text) > 200 else summary.original_text,
            "summary_text": summary.summary_text,
            "created_at": summary.created_at
        } for summary in summaries]
        
        return Response({
            "count": len(data),
            "summaries": data
        }, status=200)
    
    except Exception as e:
        return Response({"error": str(e)}, status=500)

@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def delete_summary(request, summary_id):
    """Delete a summary (only if it belongs to the user)"""
    try:
        summary = Summary.objects.get(id=summary_id, user=request.user)
        summary.delete()
        
        return Response({
            "message": "Summary deleted successfully"
        }, status=200)
    
    except Summary.DoesNotExist:
        return Response({"error": "Summary not found or unauthorized"}, status=404)
    except Exception as e:
        return Response({"error": str(e)}, status=500)