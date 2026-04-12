from django.test import TestCase
from django.urls import reverse
from unittest.mock import patch, MagicMock

class SummaryApiTests(TestCase):
    def setUp(self):
        self.url = reverse('summarize_text') # Ensure this matches your urls.py name

    @patch('api.views.genai.Client')
    def test_summarize_success(self, mock_client_class):
        """Test successful summary generation with mocked Gemini response."""
        # Setup the mock to return a fake summary
        mock_client = MagicMock()
        mock_response = MagicMock()
        mock_response.text = "This is a mocked summary of the text."
        mock_client.models.generate_content.return_value = mock_response
        mock_client_class.return_value = mock_client
        
        data = {'text': 'This is a long piece of text that needs summarizing.'}
        response = self.client.post(self.url, data, content_type='application/json')
        
        self.assertEqual(response.status_code, 200)
        self.assertIn('summary', response.json())
        self.assertEqual(response.json()['summary'], "This is a mocked summary of the text.")

    def test_summarize_empty_text(self):
        """Test that sending empty text returns a 400 error."""
        data = {'text': ''}
        response = self.client.post(self.url, data, content_type='application/json')
        
        self.assertEqual(response.status_code, 400)