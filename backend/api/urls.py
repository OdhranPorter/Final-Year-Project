from django.urls import path
from .views import summarize_text

urlpatterns = [
    path('summarize/', summarize_text),
]