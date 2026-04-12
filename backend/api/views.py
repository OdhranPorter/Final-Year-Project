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
    """Register a new user account."""
    try:
        email = request.data.get('email')
        username = request.data.get('username')
        password = request.data.get('password')
        first_name = request.data.get('first_name', '')
        last_name = request.data.get('last_name', '')

        if not all([email, username, password]):
            return Response(
                {"error": "email, username, and password required"},
                status=HTTP_400_BAD_REQUEST
            )

        if User.objects.filter(username=username).exists():
            return Response(
                {"error": "Username already exists"},
                status=HTTP_400_BAD_REQUEST
            )

        if User.objects.filter(email=email).exists():
            return Response(
                {"error": "Email already exists"},
                status=HTTP_400_BAD_REQUEST
            )

        user = User.objects.create_user(
            username=username,
            email=email,
            password=password,
            first_name=first_name,
            last_name=last_name
        )

        return Response({
            "id": user.id,
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
    """Authenticate user and return their ID."""
    try:
        username = request.data.get('username')
        password = request.data.get('password')

        if not username or not password:
            return Response(
                {"error": "username and password required"},
                status=HTTP_400_BAD_REQUEST
            )

        try:
            user = User.objects.get(username=username)
        except User.DoesNotExist:
            return Response(
                {"error": "Invalid credentials"},
                status=HTTP_400_BAD_REQUEST
            )

        if not user.check_password(password):
            return Response(
                {"error": "Invalid credentials"},
                status=HTTP_400_BAD_REQUEST
            )

        return Response({
            "id": user.id,
            "username": user.username,
            "email": user.email,
            "message": "Login successful"
        }, status=HTTP_200_OK)

    except Exception as e:
        return Response(
            {"error": str(e)},
            status=HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(['POST'])
def summarize_text(request):
    """Summarize text using Gemini AI."""
    user_text = request.data.get('text')
    
    if not user_text:
        return Response({"error": "No text provided"}, status=HTTP_400_BAD_REQUEST)

    try:
        model = genai.GenerativeModel('gemini-2.5-flash')
        prompt = f"Summarize briefly in 3 bullet points:\n\n{user_text}"
        response = model.generate_content(prompt)
        
        return Response({
            "summary": response.text,
            "original_length": len(user_text)
        }, status=HTTP_200_OK)

    except Exception as e:
        return Response({"error": str(e)}, status=HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
def generate_quiz(request):
    """Generate quiz questions from text."""
    user_id = request.data.get('user_id')
    user_text = request.data.get('text')
    
    if not user_id or not user_text:
        return Response(
            {"error": "user_id and text required"},
            status=HTTP_400_BAD_REQUEST
        )

    try:
        user = User.objects.get(id=user_id)
    except User.DoesNotExist:
        return Response({"error": "User not found"}, status=HTTP_400_BAD_REQUEST)
    
    try:
        model = genai.GenerativeModel('gemini-2.5-flash')
        
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
        
        response = model.generate_content(prompt)
        response_text = response.text.strip()
        
        # Parse JSON with fallback
        try:
            questions_data = json.loads(response_text)
        except json.JSONDecodeError:
            try:
                start = response_text.find('[')
                end = response_text.rfind(']') + 1
                if start != -1 and end > start:
                    json_str = response_text[start:end]
                    questions_data = json.loads(json_str)
                else:
                    return Response(
                        {"error": "AI returned invalid JSON"},
                        status=HTTP_500_INTERNAL_SERVER_ERROR
                    )
            except json.JSONDecodeError:
                return Response(
                    {"error": "AI response was not valid JSON"},
                    status=HTTP_500_INTERNAL_SERVER_ERROR
                )
        
        if not isinstance(questions_data, list) or len(questions_data) == 0:
            return Response(
                {"error": "Invalid quiz structure from AI"},
                status=HTTP_500_INTERNAL_SERVER_ERROR
            )
        
        # Create Quiz
        quiz = Quiz.objects.create(
            user=user,
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
                    continue
                
                question = Question.objects.create(
                    quiz=quiz,
                    question_text=question_text,
                    correct_answer=correct_answer
                )
                
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
                continue
        
        return Response({
            "quiz_id": quiz.id,
            "total_questions": len(formatted_questions),
            "questions": formatted_questions
        }, status=HTTP_200_OK)
    
    except Exception as e:
        return Response({"error": f"Server error: {str(e)}"}, status=HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
def save_note(request):
    """Save a note with extracted text and AI summary."""
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

        # Create summary
        summary = Summary.objects.create(
            note=note,
            original_text=original_text,
            summary_text=processed_content,
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
    """Get all notes for a user."""
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
                    "text": summary.summary_text if summary else None
                },
                "created_at": note.created_at.isoformat()
            })
        
        return Response({"notes": notes_data}, status=HTTP_200_OK)
    
    except Exception as e:
        return Response({"error": str(e)}, status=HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
def save_quiz_result(request):
    """Save quiz results."""
    try:
        quiz_id = request.data.get('quiz_id')
        score = request.data.get('score')

        if not quiz_id or score is None:
            return Response(
                {"error": "quiz_id and score required"},
                status=HTTP_400_BAD_REQUEST
            )

        try:
            quiz = Quiz.objects.get(id=quiz_id)
        except Quiz.DoesNotExist:
            return Response({"error": "Quiz not found"}, status=HTTP_400_BAD_REQUEST)

        quiz.score = score
        quiz.save()

        return Response({
            "quiz_id": quiz.id,
            "score": quiz.score,
            "total_questions": quiz.total_questions,
            "message": "Quiz result saved"
        }, status=HTTP_200_OK)

    except Exception as e:
        return Response({"error": str(e)}, status=HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
def save_user_answer(request):
    """Save user answer to a quiz question."""
    try:
        user_id = request.data.get('user_id')
        question_id = request.data.get('question_id')
        option_id = request.data.get('option_id')

        if not all([user_id, question_id, option_id]):
            return Response(
                {"error": "user_id, question_id, and option_id required"},
                status=HTTP_400_BAD_REQUEST
            )

        try:
            user = User.objects.get(id=user_id)
            question = Question.objects.get(id=question_id)
            option = QuestionOption.objects.get(id=option_id)
        except (User.DoesNotExist, Question.DoesNotExist, QuestionOption.DoesNotExist):
            return Response(
                {"error": "User, question, or option not found"},
                status=HTTP_400_BAD_REQUEST
            )

        answer = UserAnswer.objects.create(
            user=user,
            question=question,
            selected_option=option,
            is_correct=option.is_correct
        )

        return Response({
            "answer_id": answer.id,
            "is_correct": answer.is_correct,
            "message": "Answer saved"
        }, status=HTTP_201_CREATED)

    except Exception as e:
        return Response({"error": str(e)}, status=HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
def get_quiz(request, quiz_id):
    """Get quiz questions."""
    try:
        quiz = Quiz.objects.get(id=quiz_id)
        questions = Question.objects.filter(quiz=quiz).order_by('order')
        
        questions_data = []
        for question in questions:
            options = QuestionOption.objects.filter(question=question).order_by('order')
            questions_data.append({
                "id": question.id,
                "question": question.question_text,
                "options": [{"id": opt.id, "text": opt.option_text} for opt in options],
            })
        
        return Response({
            "quiz_id": quiz.id,
            "total_questions": quiz.total_questions,
            "questions": questions_data
        }, status=HTTP_200_OK)

    except Quiz.DoesNotExist:
        return Response({"error": "Quiz not found"}, status=HTTP_400_BAD_REQUEST)
    except Exception as e:
        return Response({"error": str(e)}, status=HTTP_500_INTERNAL_SERVER_ERROR)