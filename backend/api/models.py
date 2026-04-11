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

# 3. Quiz Table Stores AI-generated questions and user performance
class Quiz(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='quizzes')
    note = models.ForeignKey(Note, on_delete=models.SET_NULL, null=True, blank=True)
    title = models.CharField(max_length=255, default="Quiz")
    score = models.IntegerField(default=0)
    total_questions = models.IntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Quiz {self.id} (Score: {self.score}/{self.total_questions})"


# 4. Question Table - Each question in a quiz
class Question(models.Model):
    QUESTION_TYPES = [
        ('multiple_choice', 'Multiple Choice'),
        ('true_false', 'True/False'),
        ('short_answer', 'Short Answer'),
    ]
    
    quiz = models.ForeignKey(Quiz, on_delete=models.CASCADE, related_name='questions')
    question_text = models.TextField()
    question_type = models.CharField(max_length=20, choices=QUESTION_TYPES)
    correct_answer = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Q: {self.question_text[:50]}"


# 5. QuestionOption Table - For multiple choice options
class QuestionOption(models.Model):
    question = models.ForeignKey(Question, on_delete=models.CASCADE, related_name='options')
    option_text = models.TextField()
    is_correct = models.BooleanField(default=False)

    def __str__(self):
        return self.option_text


# 6. UserAnswer Table - User's responses to questions
class UserAnswer(models.Model):
    quiz = models.ForeignKey(Quiz, on_delete=models.CASCADE, related_name='user_answers')
    question = models.ForeignKey(Question, on_delete=models.CASCADE)
    user_response = models.TextField()
    is_correct = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Answer to Q{self.question.id}: {self.user_response[:30]}"
