from django.urls import path
from .views import (
    register_user,
    login_user,
    summarize_text, 
    generate_quiz, 
    save_quiz_result, 
    save_user_answer,
    get_user_sessions,
    get_quiz_history,
    save_note,
    get_user_notes
)

urlpatterns = [
    path('register/', register_user, name='register_user'),
    path('login/', login_user, name='login_user'),
    path('summarize/', summarize_text, name='summarize_text'),
    path('generate-quiz/', generate_quiz, name='generate_quiz'),
    path('quizzes/save/', save_quiz_result, name='save_quiz_result'),
    path('answers/save/', save_user_answer, name='save_user_answer'),
    path('sessions/', get_user_sessions, name='get_user_sessions'),
    path('quizzes/history/', get_quiz_history, name='get_quiz_history'),
    path('notes/save/', save_note, name='save_note'),
    path('notes/', get_user_notes, name='get_user_notes'),
]