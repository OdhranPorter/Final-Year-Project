from django.db import models
from django.contrib.auth.models import User

#Notes Table, Stores raw content from the user
class Note(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='notes')
    title = models.CharField(max_length=255)
    content = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.title

#Summary Table Stores AI-generated summaries linked to notes
class Summary(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='summaries')
    note = models.OneToOneField(Note, on_delete=models.CASCADE, related_name='summary', null=True, blank=True)
    original_text = models.TextField()
    summary_text = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Summary for {self.user.username}"

# 3Quiz Table Stores AI-generated questions and user performance
class Quiz(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='quizzes')
    note = models.ForeignKey(Note, on_delete=models.SET_NULL, null=True, blank=True)
    quiz_data = models.JSONField()  #Stores questions as a JSON object
    score = models.IntegerField(default=0)
    total_questions = models.IntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Quiz {self.id} (Score: {self.score}/{self.total_questions})"
