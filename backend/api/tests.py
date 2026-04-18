from django.test import TestCase
from django.urls import reverse
from django.contrib.auth.models import User
from rest_framework_simplejwt.tokens import RefreshToken
from unittest.mock import patch, MagicMock
from .models import Flashcard, FlashcardCard, Quiz, Question, QuestionOption, TestScore

class AuthenticationTests(TestCase):
    """Test user registration and authentication"""
    
    def test_register_user_success(self):
        """Test successful user registration"""
        url = reverse('register_user')
        data = {'username': 'testuser', 'password': 'password123'}
        response = self.client.post(url, data, content_type='application/json')
        
        self.assertEqual(response.status_code, 201)
        self.assertIn('access', response.json())
        self.assertIn('refresh', response.json())
    
    def test_register_user_invalid_password(self):
        """Test registration fails with short password"""
        url = reverse('register_user')
        data = {'username': 'testuser', 'password': '123'}
        response = self.client.post(url, data, content_type='application/json')
        
        self.assertEqual(response.status_code, 400)


class SummarizationTests(TestCase):
    """Test AI summarization feature"""
    
    def setUp(self):
        self.url = reverse('summarize_text')
        self.user = User.objects.create_user(username='testuser', password='pass123')
        refresh = RefreshToken.for_user(self.user)
        self.headers = {'HTTP_AUTHORIZATION': f'Bearer {str(refresh.access_token)}', 'content_type': 'application/json'}

    @patch('api.views.google.genai.Client')
    @patch('api.views.os.getenv')
    def test_summarize_success(self, mock_getenv, mock_client_class):
        """Test successful text summarization"""
        mock_getenv.return_value = "fake-api-key"
        mock_client = MagicMock()
        mock_response = MagicMock()
        mock_response.text = "Summary: Key points here."
        mock_client.models.generate_content.return_value = mock_response
        mock_client_class.return_value = mock_client
        
        response = self.client.post(self.url, {'text': 'Long text to summarize...'}, **self.headers)
        self.assertEqual(response.status_code, 200)
        self.assertIn('summary', response.json())
    
    def test_summarize_unauthorized(self):
        """Test summarization fails without auth token"""
        response = self.client.post(self.url, {'text': 'Some text'}, content_type='application/json')
        self.assertEqual(response.status_code, 401)


class QuizGenerationTests(TestCase):
    """Test quiz generation feature"""
    
    def setUp(self):
        self.url = reverse('generate_quiz')
        self.user = User.objects.create_user(username='testuser', password='pass123')
        refresh = RefreshToken.for_user(self.user)
        self.headers = {'HTTP_AUTHORIZATION': f'Bearer {str(refresh.access_token)}', 'content_type': 'application/json'}

    @patch('api.views.google.genai.Client')
    @patch('api.views.os.getenv')
    def test_generate_quiz_success(self, mock_getenv, mock_client_class):
        """Test successful quiz generation"""
        mock_getenv.return_value = "fake-api-key"
        mock_client = MagicMock()
        mock_response = MagicMock()
        mock_response.text = '{"questions": [{"question": "Q1?", "options": ["A", "B", "C", "D"], "correct_index": 0}]}'
        mock_client.models.generate_content.return_value = mock_response
        mock_client_class.return_value = mock_client
        
        response = self.client.post(self.url, {'text': 'Study notes...'}, **self.headers)
        self.assertEqual(response.status_code, 200)
        self.assertIn('questions', response.json())
    
    def test_generate_quiz_unauthorized(self):
        """Test quiz generation fails without token"""
        response = self.client.post(self.url, {'text': 'Some text'}, content_type='application/json')
        self.assertEqual(response.status_code, 401)


class FlashcardTests(TestCase):
    """Test flashcard generation and management"""
    
    def setUp(self):
        self.user = User.objects.create_user(username='testuser', password='pass123')
        refresh = RefreshToken.for_user(self.user)
        token = str(refresh.access_token)
        self.headers = {'HTTP_AUTHORIZATION': f'Bearer {token}', 'content_type': 'application/json'}
        self.gen_url = reverse('generate_flashcards')
        self.save_url = reverse('save_flashcards')
        self.get_url = reverse('get_user_flashcards')

    @patch('api.views.google.genai.Client')
    @patch('api.views.os.getenv')
    def test_generate_flashcards_success(self, mock_getenv, mock_client_class):
        """Test successful flashcard generation"""
        mock_getenv.return_value = "fake-api-key"
        mock_client = MagicMock()
        mock_response = MagicMock()
        mock_response.text = '{"cards": [{"question": "Q?", "answer": "A"}]}'
        mock_client.models.generate_content.return_value = mock_response
        mock_client_class.return_value = mock_client
        
        response = self.client.post(self.gen_url, {'text': 'Study notes...'}, **self.headers)
        self.assertEqual(response.status_code, 200)
        self.assertIn('cards', response.json())
    
    def test_save_and_retrieve_flashcards(self):
        """Test saving and retrieving flashcards"""
        cards = [{"question": "What is DNA?", "answer": "Genetic material"}]
        data = {'title': 'Biology', 'cards': cards, 'subject_class': 'Bio 101', 'year': '2024'}
        
        save_response = self.client.post(self.save_url, data, **self.headers)
        self.assertEqual(save_response.status_code, 201)
        
        get_response = self.client.get(self.get_url, **self.headers)
        self.assertEqual(get_response.status_code, 200)
        self.assertGreater(len(get_response.json()['flashcards']), 0)


class QuizResultsTests(TestCase):
    """Test saving quiz results"""
    
    def setUp(self):
        self.user = User.objects.create_user(username='testuser', password='pass123')
        refresh = RefreshToken.for_user(self.user)
        self.headers = {'HTTP_AUTHORIZATION': f'Bearer {str(refresh.access_token)}', 'content_type': 'application/json'}
        self.url = reverse('save_quiz_results')

    def test_save_quiz_results_success(self):
        """Test successful quiz results saving"""
        data = {
            'score': 4,
            'total_questions': 5,
            'questions': [
                {'question': 'Q1?', 'options': ['A', 'B', 'C', 'D'], 'correct_index': 0}
            ]
        }
        response = self.client.post(self.url, data, **self.headers)
        self.assertEqual(response.status_code, 201)
        self.assertIn('quiz_id', response.json())


class ProgressTrackingTests(TestCase):
    """Test progress tracking with test scores"""
    
    def setUp(self):
        self.user = User.objects.create_user(username='testuser', password='pass123')
        refresh = RefreshToken.for_user(self.user)
        self.headers = {'HTTP_AUTHORIZATION': f'Bearer {str(refresh.access_token)}', 'content_type': 'application/json'}
        self.url = reverse('add_test_score')

    def test_add_test_score_success(self):
        """Test adding a test score"""
        import datetime
        data = {
            'subject_class': 'Physics 101',
            'year': '2024',
            'score': 85.5,
            'test_date': str(datetime.date.today()),
            'test_name': 'Midterm'
        }
        response = self.client.post(self.url, data, **self.headers)
        self.assertEqual(response.status_code, 201)