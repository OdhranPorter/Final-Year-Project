from django.test import TestCase
from django.urls import reverse
from django.contrib.auth.models import User
from rest_framework_simplejwt.tokens import RefreshToken
from unittest.mock import patch, MagicMock

class SummaryApiTests(TestCase):
    def setUp(self):
        self.url = reverse('summarize_text')
        
        # Create a test user
        self.user = User.objects.create_user(
            username='testuser',
            password='testpass123'
        )
        
        # Generate JWT token for the test user
        refresh = RefreshToken.for_user(self.user)
        self.token = str(refresh.access_token)
        
        # Setup headers with authorization
        self.headers = {
            'HTTP_AUTHORIZATION': f'Bearer {self.token}',
            'content_type': 'application/json'
        }

    @patch('api.views.os.getenv')
    @patch('api.views.genai.Client')
    def test_summarize_success(self, mock_client_class, mock_getenv):
        """Test successful summary generation with mocked Gemini response."""
        # Mock the environment variable
        mock_getenv.return_value = "fake-api-key"
        
        # Setup the mock to return a fake summary
        mock_client = MagicMock()
        mock_response = MagicMock()
        mock_response.text = "This is a mocked summary of the text."
        mock_client.models.generate_content.return_value = mock_response
        mock_client_class.return_value = mock_client
        
        data = {'text': 'This is a long piece of text that needs summarizing.'}
        response = self.client.post(self.url, data, **self.headers)
        
        self.assertEqual(response.status_code, 200)
        self.assertIn('summary', response.json())
        self.assertEqual(response.json()['summary'], "This is a mocked summary of the text.")

    def test_summarize_empty_text(self):
        """Test that sending empty text returns a 400 error."""
        data = {'text': ''}
        response = self.client.post(self.url, data, **self.headers)
        
        self.assertEqual(response.status_code, 400)
    
    def test_summarize_unauthorized(self):
        """Test that requests without token are rejected."""
        data = {'text': 'This should fail without auth token.'}
        response = self.client.post(self.url, data, content_type='application/json')
        
        self.assertEqual(response.status_code, 401)