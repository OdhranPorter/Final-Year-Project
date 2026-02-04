from django.test import TestCase
from django.urls import reverse
from unittest.mock import patch

class SummaryApiTests(TestCase):
    def setUp(self):
        self.url = reverse('summarize_text') # Ensure this matches your urls.py name

    @patch('google.generativeai.GenerativeModel.generate_content')
    def test_summarize_success(self, mock_gemini):
        """Test successful summary generation with mocked Gemini response."""
        # Setup the mock to return a fake summary
        mock_gemini.return_value.text = "This is a mocked summary of the text."
        
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