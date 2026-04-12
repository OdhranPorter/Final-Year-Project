from django.contrib import admin
from .models import Note, Summary, Quiz, TestScore

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

@admin.register(TestScore)
class TestScoreAdmin(admin.ModelAdmin):
    list_display = ('user', 'subject_class', 'year', 'score', 'test_date', 'test_name', 'created_at')
    search_fields = ('subject_class', 'test_name')
    list_filter = ('subject_class', 'year', 'test_date')
    readonly_fields = ('created_at',)
