from django.shortcuts import render
from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework.status import HTTP_200_OK, HTTP_400_BAD_REQUEST, HTTP_500_INTERNAL_SERVER_ERROR, HTTP_201_CREATED, HTTP_401_UNAUTHORIZED
import google.generativeai as genai
import os
from dotenv import load_dotenv
import json
from .models import Quiz, Question, QuestionOption, UserAnswer, Note, Summary
from django.contrib.auth.models import User
from django.contrib.auth.hashers import make_password, check_password

# Load the API key from the .env file
load_dotenv()
genai.configure(api_key=os.getenv("GEMINI_API_KEY"))


@api_view(['POST'])
def register_user(request):
    """
    Register a new user account.
    
    Expected request:
    {
        'email': 'user@example.com',
        'username': 'username',
        'password': 'password123',
        'first_name': 'John',
        'last_name': 'Doe'
    }
    """
    try:
        email = request.data.get('email')
        username = request.data.get('username')
        password = request.data.get('password')
        first_name = request.data.get('first_name', '')
        last_name = request.data.get('last_name', '')

        # Validation
        if not all([email, username, password]):
            return Response(
                {"error": "Email, username, and password are required"},
                status=HTTP_400_BAD_REQUEST
            )

        # Check if user already exists
        if User.objects.filter(email=email).exists():
            return Response(
                {"error": "Email already registered"},
                status=HTTP_400_BAD_REQUEST
            )

        if User.objects.filter(username=username).exists():
            return Response(
                {"error": "Username already taken"},
                status=HTTP_400_BAD_REQUEST
            )

        # Create new user
        user = User.objects.create_user(
            email=email,
            username=username,
            password=password,
            first_name=first_name,
            last_name=last_name
        )

        return Response({
            "user_id": user.id,
            "username": user.username,
            "email": user.email,
            "message": "User registered successfully"
        }, status=HTTP_201_CREATED)

    except Exception as e:
        return Response(
            {"error": str(e)},
            status=HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(['POST'])
def login_user(request):
    """
    Authenticate a user and return their ID.
    
    Expected request:
    {
        'email': 'user@example.com',
        'password': 'password123'
    }
    """
    try:
        email = request.data.get('email')
        password = request.data.get('password')

        if not all([email, password]):
            return Response(
                {"error": "Email and password are required"},
                status=HTTP_400_BAD_REQUEST
            )

        # Find user by email
        try:
            user = User.objects.get(email=email)
        except User.DoesNotExist:
            return Response(
                {"error": "Invalid email or password"},
                status=HTTP_401_UNAUTHORIZED
            )

        # Check password
        if not user.check_password(password):
            return Response(
                {"error": "Invalid email or password"},
                status=HTTP_401_UNAUTHORIZED
            )

        return Response({
            "user_id": user.id,
            "username": user.username,
            "email": user.email,
            "first_name": user.first_name,
            "message": "Login successful"
        }, status=HTTP_200_OK)

    except Exception as e:
        return Response(
            {"error": str(e)},
            status=HTTP_500_INTERNAL_SERVER_ERROR
        )




@api_view(['POST'])
def summarize_text(request):
    # 1. Get the text from the request (sent by Flutter later)
    user_text = request.data.get('text')
    
    if not user_text:
        return Response({"error": "No text provided"}, status=HTTP_400_BAD_REQUEST)

    try:
        # 2. Configure the Gemini Model (using lighter model to reduce tokens)
        model = genai.GenerativeModel('gemini-2.0-flash-lite')

        # 3. Create a prompt (concise prompt to minimize tokens)
        prompt = f"Summarize briefly in 3 bullet points:\n\n{user_text}"

        # 4. Generate Content
        response = model.generate_content(prompt)
        
        # 5. Return the result as JSON
        return Response({
            "summary": response.text,
            "original_length": len(user_text)
        })

    except Exception as e:
        import traceback
        print(f"=== SUMMARIZE ERROR ===")
        print(f"Error type: {type(e).__name__}")
        print(f"Error message: {str(e)}")
        traceback.print_exc()
        print("=======================")
        return Response({"error": str(e)}, status=HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
def generate_quiz(request):
    """
    Generate a quiz from notes using Gemini AI.
    
    Expected request:
    {
        "text": "The student's study notes",
        "user_id": 1
    }
    
    Returns:
    {
        "quiz_id": 5,
        "questions": [
            {
                "question": "What is...",
                "options": ["A", "B", "C", "D"],
                "correct_answer": "A"
            }
        ]
    }
    """
    user_text = request.data.get('text')
    user_id = request.data.get('user_id')
    
    if not user_text:
        return Response({"error": "No text provided"}, status=HTTP_400_BAD_REQUEST)
    if not user_id:
        return Response({"error": "No user_id provided"}, status=HTTP_400_BAD_REQUEST)
    
    try:
        # Get user
        user = User.objects.get(id=user_id)
    except User.DoesNotExist:
        return Response({"error": "User not found"}, status=HTTP_400_BAD_REQUEST)
    
    try:
        # Configure Gemini (using lighter model to reduce tokens)
        model = genai.GenerativeModel('gemini-2.0-flash-lite')
        
        # Craft a specific prompt for quiz generation
        prompt = f"""Generate 5 MC questions from these notes:\n\n{user_text}\n\nReturn ONLY valid JSON in this exact format, no other text:
[
  {{
    "question": "question text here?",
    "options": ["option A", "option B", "option C", "option D"],
    "correct_answer": "option A"
  }}
]

Rules:
- Generate exactly 5 questions
- Each question has exactly 4 options
- correct_answer must be one of the 4 options
- Make questions test understanding, not trivial facts
- Return ONLY the JSON array, nothing else"""
        
        # Generate response
        response = model.generate_content(prompt)
        response_text = response.text.strip()
        
        # Parse JSON - with retry logic if it fails
        try:
            questions_data = json.loads(response_text)
        except json.JSONDecodeError:
            # Try to extract JSON if Gemini adds extra text
            try:
                start = response_text.find('[')
                end = response_text.rfind(']') + 1
                if start != -1 and end > start:
                    json_str = response_text[start:end]
                    questions_data = json.loads(json_str)
                else:
                    return Response(
                        {"error": "AI returned invalid JSON and could not be parsed"},
                        status=HTTP_500_INTERNAL_SERVER_ERROR
                    )
            except json.JSONDecodeError:
                return Response(
                    {"error": "AI response was not valid JSON"},
                    status=HTTP_500_INTERNAL_SERVER_ERROR
                )
        
        # Validate structure
        if not isinstance(questions_data, list) or len(questions_data) == 0:
            return Response(
                {"error": "Invalid quiz structure from AI"},
                status=HTTP_500_INTERNAL_SERVER_ERROR
            )
        
        # Create Quiz object
        quiz = Quiz.objects.create(
            user=user,
            title=f"Quiz from Study Session",
            total_questions=len(questions_data)
        )
        
        # Create Questions and Options
        formatted_questions = []
        for q_data in questions_data:
            try:
                question_text = q_data.get('question', '')
                options = q_data.get('options', [])
                correct_answer = q_data.get('correct_answer', '')
                
                if not question_text or len(options) != 4 or not correct_answer:
                    continue  # Skip malformed questions
                
                # Create Question
                question = Question.objects.create(
                    quiz=quiz,
                    question_text=question_text,
                    question_type='multiple_choice',
                    correct_answer=correct_answer
                )
                
                # Create Options
                created_options = []
                for option_text in options:
                    q_option = QuestionOption.objects.create(
                        question=question,
                        option_text=option_text,
                        is_correct=(option_text == correct_answer)
                    )
                    created_options.append({
                        "id": q_option.id,
                        "text": q_option.option_text
                    })
                
                formatted_questions.append({
                    "question_id": question.id,
                    "question": question_text,
                    "options": created_options,
                    "correct_answer": correct_answer
                })
            except Exception as e:
                continue  # Skip problematic questions
        
        return Response({
            "quiz_id": quiz.id,
            "total_questions": len(formatted_questions),
            "questions": formatted_questions
        }, status=HTTP_200_OK)
    
    except Exception as e:
        return Response({"error": f"Server error: {str(e)}"}, status=HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
def save_quiz_result(request):
    """
    Save quiz results after user completes the quiz.
    
    Expected request:
    {
        "quiz_id": 5,
        "score": 4,
        "total_questions": 5
    }
    """
    quiz_id = request.data.get('quiz_id')
    score = request.data.get('score')
    total_questions = request.data.get('total_questions')
    
    if not quiz_id:
        return Response({"error": "No quiz_id provided"}, status=HTTP_400_BAD_REQUEST)
    
    try:
        quiz = Quiz.objects.get(id=quiz_id)
        quiz.score = score
        quiz.total_questions = total_questions
        quiz.save()
        
        return Response({
            "success": True,
            "quiz_id": quiz.id,
            "score": quiz.score,
            "total_questions": quiz.total_questions
        }, status=HTTP_200_OK)
    
    except Quiz.DoesNotExist:
        return Response({"error": "Quiz not found"}, status=HTTP_400_BAD_REQUEST)
    except Exception as e:
        return Response({"error": str(e)}, status=HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
def save_user_answer(request):
    """
    Save individual user answer.
    
    Expected request:
    {
        "quiz_id": 5,
        "question_id": 12,
        "user_response": "option text",
        "is_correct": true
    }
    """
    quiz_id = request.data.get('quiz_id')
    question_id = request.data.get('question_id')
    user_response = request.data.get('user_response')
    is_correct = request.data.get('is_correct', False)
    
    if not all([quiz_id, question_id, user_response]):
        return Response({"error": "Missing required fields"}, status=HTTP_400_BAD_REQUEST)
    
    try:
        quiz = Quiz.objects.get(id=quiz_id)
        question = Question.objects.get(id=question_id)
        
        user_answer = UserAnswer.objects.create(
            quiz=quiz,
            question=question,
            user_response=user_response,
            is_correct=is_correct
        )
        
        return Response({
            "success": True,
            "answer_id": user_answer.id
        }, status=HTTP_200_OK)
    
    except (Quiz.DoesNotExist, Question.DoesNotExist):
        return Response({"error": "Quiz or Question not found"}, status=HTTP_400_BAD_REQUEST)
    except Exception as e:
        return Response({"error": str(e)}, status=HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
def get_user_sessions(request):
    """
    Get all study sessions (notes/summaries) for a user.
    
    Query params:
    - user_id (required)
    
    Returns:
    {
        "sessions": [
            {
                "id": 1,
                "title": "Biology Chapter 5",
                "created_at": "2026-04-11T10:30:00Z",
                "quiz_count": 3,
                "summary": "Brief summary..."
            }
        ]
    }
    """
    user_id = request.query_params.get('user_id')
    
    if not user_id:
        return Response({"error": "user_id required"}, status=HTTP_400_BAD_REQUEST)
    
    try:
        user = User.objects.get(id=user_id)
    except User.DoesNotExist:
        return Response({"error": "User not found"}, status=HTTP_400_BAD_REQUEST)
    
    try:
        # Get all notes/summaries for user, sorted by date
        summaries = Summary.objects.filter(user=user).order_by('-created_at')
        
        sessions = []
        for summary in summaries:
            quiz_count = Quiz.objects.filter(user=user, note=summary.note).count()
            sessions.append({
                "id": summary.id,
                "note_id": summary.note.id if summary.note else None,
                "title": summary.note.title if summary.note else "Untitled",
                "created_at": summary.created_at.isoformat(),
                "quiz_count": quiz_count,
                "summary_text": summary.summary_text[:100] + "..." if len(summary.summary_text) > 100 else summary.summary_text
            })
        
        return Response({"sessions": sessions}, status=HTTP_200_OK)
    
    except Exception as e:
        return Response({"error": str(e)}, status=HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
def get_quiz_history(request):
    """
    Get all completed quizzes for a user.
    
    Query params:
    - user_id (required)
    
    Returns:
    {
        "quizzes": [
            {
                "id": 1,
                "title": "Quiz 1",
                "score": 4,
                "total_questions": 5,
                "percentage": 80,
                "created_at": "2026-04-11T10:30:00Z"
            }
        ]
    }
    """
    user_id = request.query_params.get('user_id')
    
    if not user_id:
        return Response({"error": "user_id required"}, status=HTTP_400_BAD_REQUEST)
    
    try:
        user = User.objects.get(id=user_id)
    except User.DoesNotExist:
        return Response({"error": "User not found"}, status=HTTP_400_BAD_REQUEST)
    
    try:
        quizzes = Quiz.objects.filter(user=user).order_by('-created_at')
        
        quiz_data = []
        for quiz in quizzes:
            percentage = int((quiz.score / quiz.total_questions * 100)) if quiz.total_questions > 0 else 0
            quiz_data.append({
                "id": quiz.id,
                "title": quiz.title,
                "score": quiz.score,
                "total_questions": quiz.total_questions,
                "percentage": percentage,
                "created_at": quiz.created_at.isoformat()
            })
        
        return Response({"quizzes": quiz_data}, status=HTTP_200_OK)
    
    except Exception as e:
        return Response({"error": str(e)}, status=HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
def save_note(request):
    """
    Save a note with extracted text and Gemini analysis.
    
    Expected request:
    {
        'user_id': 1,
        'title': 'Note title',
        'original_text': 'extracted text from image',
        'processed_content': 'gemini ai response'
    }
    """
    try:
        user_id = request.data.get('user_id')
        title = request.data.get('title')
        original_text = request.data.get('original_text')
        processed_content = request.data.get('processed_content')

        if not all([user_id, title, original_text, processed_content]):
            return Response(
                {"error": "user_id, title, original_text, and processed_content required"},
                status=HTTP_400_BAD_REQUEST
            )

        # Get user
        try:
            user = User.objects.get(id=user_id)
        except User.DoesNotExist:
            return Response({"error": "User not found"}, status=HTTP_400_BAD_REQUEST)

        # Create note
        note = Note.objects.create(
            user=user,
            title=title,
            content=original_text
        )

        # Create summary linked to the note
        summary = Summary.objects.create(
            note=note,
            text=processed_content,
            user=user
        )

        return Response({
            "note_id": note.id,
            "summary_id": summary.id,
            "title": note.title,
            "created_at": note.created_at.isoformat(),
            "message": "Note saved successfully"
        }, status=HTTP_201_CREATED)

    except Exception as e:
        return Response(
            {"error": str(e)},
            status=HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(['GET'])
def get_user_notes(request):
    """
    Get all notes for a user.
    
    Query params:
    - user_id (required)
    
    Returns:
    {
        "notes": [
            {
                "id": 1,
                "title": "Note title",
                "content": "extracted text...",
                "summary": {
                    "id": 1,
                    "text": "gemini analysis..."
                },
                "created_at": "2026-04-11T10:30:00Z"
            }
        ]
    }
    """
    user_id = request.query_params.get('user_id')
    
    if not user_id:
        return Response({"error": "user_id required"}, status=HTTP_400_BAD_REQUEST)
    
    try:
        user = User.objects.get(id=user_id)
    except User.DoesNotExist:
        return Response({"error": "User not found"}, status=HTTP_400_BAD_REQUEST)
    
    try:
        notes = Note.objects.filter(user=user).order_by('-created_at')
        
        notes_data = []
        for note in notes:
            summary = Summary.objects.filter(note=note).first()
            notes_data.append({
                "id": note.id,
                "title": note.title,
                "content": note.content,
                "summary": {
                    "id": summary.id if summary else None,
                    "text": summary.text if summary else None
                },
                "created_at": note.created_at.isoformat()
            })
        
        return Response({"notes": notes_data}, status=HTTP_200_OK)
    
    except Exception as e:
        return Response({"error": str(e)}, status=HTTP_500_INTERNAL_SERVER_ERROR)