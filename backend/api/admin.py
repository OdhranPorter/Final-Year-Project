from django.contrib import admin
from .models import Note, Summary, Quiz

@admin.register(Note)
class NoteAdmin(admin.ModelAdmin):
    list_display = ('title', 'user', 'created_at')
    search_fields = ('title', 'content')

@admin.register(Summary)
class SummaryAdmin(admin.ModelAdmin):
    list_display = ('user', 'note', 'created_at')

@admin.register(Quiz)
class QuizAdmin(admin.ModelAdmin):
    list_display = ('user', 'score', 'total_questions', 'created_at')
