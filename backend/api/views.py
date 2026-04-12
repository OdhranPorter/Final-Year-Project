from django.shortcuts import render
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth.models import User
import google.genai as genai
import os
from dotenv import load_dotenv
import json
import re
from .models import Summary, Quiz, Question, QuestionOption

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

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def generate_quiz(request):
    """Generate a quiz from user notes using Gemini AI"""
    text = request.data.get('text')
    
    if not text or len(text.strip()) == 0:
        return Response({"error": "Text is required to generate quiz"}, status=400)
    
    try:
        api_key = os.getenv("GEMINI_API_KEY")
        if not api_key:
            return Response({"error": "GEMINI_API_KEY not configured"}, status=500)
        
        try:
            client = genai.Client(api_key=api_key)
        except Exception as e:
            # Try alternative initialization method
            import google.generativeai
            google.generativeai.configure(api_key=api_key)
            client = genai
        
        # Prompt to generate multiple-choice questions
        prompt = f"""Generate exactly 5 multiple-choice quiz questions based on these study notes. 
Return ONLY valid JSON with this structure (no other text):
{{
  "questions": [
    {{
      "question": "Question text here?",
      "options": ["Option A", "Option B", "Option C", "Option D"],
      "correct_index": 0
    }}
  ]
}}

Study notes:
{text}"""

        try:
            response = client.models.generate_content(
                model='gemini-2.5-flash',
                contents=prompt
            )
        except Exception as e:
            # Try alternative method
            import google.generativeai
            model = google.generativeai.GenerativeModel('gemini-2.5-flash')
            response = model.generate_content(prompt)
        
        # Extract JSON from response
        response_text = response.text.strip()
        
        # Try to find JSON in the response
        json_match = re.search(r'\{[\s\S]*\}', response_text)
        if json_match:
            response_text = json_match.group()
        
        quiz_data = json.loads(response_text)
        
        return Response({
            "questions": quiz_data.get('questions', []),
            "total_questions": len(quiz_data.get('questions', []))
        }, status=200)
    
    except json.JSONDecodeError as e:
        return Response({"error": f"Failed to parse AI response: {str(e)}"}, status=500)
    except Exception as e:
        import traceback
        error_msg = f"{str(e)}\n{traceback.format_exc()}"
        return Response({"error": error_msg}, status=500)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def save_quiz_results(request):
    """Save quiz results to user's account"""
    score = request.data.get('score')
    total_questions = request.data.get('total_questions')
    questions_data = request.data.get('questions')  # Array of questions with user responses
    original_text = request.data.get('original_text', '')  # Original text used to generate quiz
    
    if score is None or total_questions is None or not questions_data:
        return Response({"error": "score, total_questions, and questions are required"}, status=400)
    
    try:
        # Create quiz record with original_text
        quiz = Quiz.objects.create(
            user=request.user,
            score=score,
            total_questions=total_questions,
            original_text=original_text
        )
        
        # Create questions and store user answers
        for q_data in questions_data:
            question = Question.objects.create(
                quiz=quiz,
                question_text=q_data.get('question', ''),
                question_type='multiple_choice',
                correct_answer=str(q_data.get('correct_index', 0))
            )
            
            # Create question options
            options = q_data.get('options', [])
            correct_index = q_data.get('correct_index', 0)
            
            for idx, option_text in enumerate(options):
                QuestionOption.objects.create(
                    question=question,
                    option_text=option_text,
                    is_correct=(idx == correct_index)
                )
        
        return Response({
            "message": "Quiz results saved successfully",
            "quiz_id": quiz.id,
            "score": score,
            "total_questions": total_questions
        }, status=201)
    
    except Exception as e:
        return Response({"error": str(e)}, status=500)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_user_quizzes(request):
    """Get all completed quizzes for the authenticated user"""
    try:
        quizzes = Quiz.objects.filter(user=request.user).order_by('-created_at')
        
        quiz_list = []
        for quiz in quizzes:
            # Calculate percentage score
            percentage = (quiz.score / quiz.total_questions * 100) if quiz.total_questions > 0 else 0
            
            # Get all questions for this quiz
            questions = Question.objects.filter(quiz=quiz)
            questions_data = []
            
            for question in questions:
                # Get options for this question
                options = QuestionOption.objects.filter(question=question)
                options_data = [
                    {
                        'option_text': opt.option_text,
                        'is_correct': opt.is_correct
                    }
                    for opt in options
                ]
                
                questions_data.append({
                    'question_text': question.question_text,
                    'correct_answer': question.correct_answer,
                    'options': options_data
                })
            
            quiz_list.append({
                'id': quiz.id,
                'score': quiz.score,
                'total_questions': quiz.total_questions,
                'percentage': round(percentage, 1),
                'created_at': quiz.created_at.isoformat(),
                'original_text': quiz.original_text,
                'questions': questions_data
            })
        
        return Response({
            "quizzes": quiz_list
        }, status=200)
    
    except Exception as e:
        return Response({"error": str(e)}, status=500)