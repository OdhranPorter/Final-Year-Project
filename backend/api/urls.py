from django.urls import path
from rest_framework_simplejwt.views import (
    TokenObtainPairView,
    TokenRefreshView,
)
from .views import summarize_text

urlpatterns = [
    #Summarize Route
    path('summarize/', summarize_text, name='summarize_text'),
    
    #Authentication Routes
    path('token/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
]