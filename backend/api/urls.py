from django.urls import path
from rest_framework_simplejwt.views import (
    TokenObtainPairView,
    TokenRefreshView,
)
from .views import summarize_text, register_user

urlpatterns = [
    # Summarize Route
    path('summarize/', summarize_text, name='summarize_text'),
    
    # Authentication Routes
    path('register/', register_user, name='register_user'),
    path('token/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
]