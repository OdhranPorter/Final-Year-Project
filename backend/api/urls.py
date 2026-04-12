from django.urls import path
from rest_framework_simplejwt.views import (
    TokenObtainPairView,
    TokenRefreshView,
)
from .views import summarize_text, register_user, save_summary, get_user_summaries, delete_summary

urlpatterns = [
    # Summarize Route
    path('summarize/', summarize_text, name='summarize_text'),
    
    # Notes/Summaries Routes
    path('notes/', get_user_summaries, name='get_user_summaries'),
    path('notes/save/', save_summary, name='save_summary'),
    path('notes/<int:summary_id>/delete/', delete_summary, name='delete_summary'),
    
    # Authentication Routes
    path('register/', register_user, name='register_user'),
    path('token/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
]