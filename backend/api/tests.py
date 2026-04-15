from django.test import TestCase
from django.urls import reverse
from django.contrib.auth.models import User
from rest_framework_simplejwt.tokens import RefreshToken
from unittest.mock import patch, MagicMock
from .models import Flashcard, FlashcardCard

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

    @patch('api.views.google.genai.Client')
    @patch('api.views.os.getenv')
    def test_summarize_success(self, mock_getenv, mock_client_class):
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


class FlashcardApiTests(TestCase):
    """Test suite for flashcard generation, saving, and retrieval endpoints"""
    
    def setUp(self):
        """Set up test user, authentication token, and URLs"""
        # Create a test user
        self.user = User.objects.create_user(
            username='flashcard_tester',
            password='flashcard_pass123'
        )
        
        # Generate JWT token for the test user
        refresh = RefreshToken.for_user(self.user)
        self.token = str(refresh.access_token)
        
        # Setup headers with authorization
        self.auth_headers = {
            'HTTP_AUTHORIZATION': f'Bearer {self.token}',
            'content_type': 'application/json'
        }
        
        # Test URLs
        self.generate_url = reverse('generate_flashcards')
        self.save_url = reverse('save_flashcards')
        self.get_url = reverse('get_user_flashcards')
        self.filter_options_url = reverse('get_flashcard_filter_options')
    
    # ============= GENERATE FLASHCARDS TESTS =============
    
    @patch('api.views.google.genai.Client')
    @patch('api.views.os.getenv')
    def test_generate_flashcards_success(self, mock_getenv, mock_client_class):
        """Test successful flashcard generation with valid input"""
        mock_getenv.return_value = "fake-api-key"
        
        # Mock Gemini response
        mock_client = MagicMock()
        mock_response = MagicMock()
        mock_response.text = '''{
            "cards": [
                {"question": "What is photosynthesis?", "answer": "Process where plants convert light to chemical energy"},
                {"question": "What is ATP?", "answer": "Adenosine triphosphate, energy currency of cells"}
            ]
        }'''
        mock_client.models.generate_content.return_value = mock_response
        mock_client_class.return_value = mock_client
        
        data = {
            'text': 'Photosynthesis is the process by which plants convert light energy into chemical energy...',
            'title': 'Biology Chapter 5',
            'subject_class': 'Biology 101',
            'year': '2024'
        }
        
        response = self.client.post(self.generate_url, data, **self.auth_headers)
        
        self.assertEqual(response.status_code, 200)
        json_response = response.json()
        self.assertIn('cards', json_response)
        self.assertIn('total_cards', json_response)
        self.assertEqual(json_response['total_cards'], 2)
        self.assertEqual(json_response['cards'][0]['question'], 'What is photosynthesis?')
    
    def test_generate_flashcards_empty_text(self):
        """Test that empty text returns a 400 error"""
        data = {
            'text': '',
            'title': 'Empty Flashcards'
        }
        
        response = self.client.post(self.generate_url, data, **self.auth_headers)
        self.assertEqual(response.status_code, 400)
        self.assertIn('error', response.json())
    
    def test_generate_flashcards_unauthorized(self):
        """Test that unauthenticated requests are rejected"""
        data = {
            'text': 'Some study notes',
            'title': 'Test Flashcards'
        }
        
        response = self.client.post(self.generate_url, data, content_type='application/json')
        self.assertEqual(response.status_code, 401)
    
    @patch('api.views.google.genai.Client')
    @patch('api.views.os.getenv')
    def test_generate_flashcards_invalid_json_response(self, mock_getenv, mock_client_class):
        """Test handling of malformed JSON from Gemini API"""
        mock_getenv.return_value = "fake-api-key"
        
        mock_client = MagicMock()
        mock_response = MagicMock()
        mock_response.text = "This is not valid JSON {invalid}"
        mock_client.models.generate_content.return_value = mock_response
        mock_client_class.return_value = mock_client
        
        data = {'text': 'Some study text'}
        response = self.client.post(self.generate_url, data, **self.auth_headers)
        
        self.assertEqual(response.status_code, 500)
        self.assertIn('error', response.json())
    
    # ============= SAVE FLASHCARDS TESTS =============
    
    def test_save_flashcards_success(self):
        """Test successful saving of flashcard sets to database"""
        cards_data = [
            {"question": "What is DNA?", "answer": "Deoxyribonucleic acid, genetic material"},
            {"question": "What are amino acids?", "answer": "Building blocks of proteins"}
        ]
        
        data = {
            'title': 'Biology Basics',
            'cards': cards_data,
            'original_text': 'DNA is the genetic material...',
            'subject_class': 'Biology 101',
            'year': '2024'
        }
        
        response = self.client.post(self.save_url, data, **self.auth_headers)
        
        self.assertEqual(response.status_code, 201)
        json_response = response.json()
        self.assertIn('flashcard_id', json_response)
        self.assertEqual(json_response['total_cards'], 2)
        self.assertEqual(json_response['message'], "Flashcards saved successfully")
        
        # Verify flashcard was created in database
        flashcard = Flashcard.objects.get(id=json_response['flashcard_id'])
        self.assertEqual(flashcard.title, 'Biology Basics')
        self.assertEqual(flashcard.user, self.user)
        
        # Verify cards were created
        cards = FlashcardCard.objects.filter(flashcard=flashcard)
        self.assertEqual(cards.count(), 2)
    
    def test_save_flashcards_empty_cards(self):
        """Test that saving with no cards returns a 400 error"""
        data = {
            'title': 'Empty Set',
            'cards': []
        }
        
        response = self.client.post(self.save_url, data, **self.auth_headers)
        self.assertEqual(response.status_code, 400)
        self.assertIn('error', response.json())
    
    def test_save_flashcards_unauthorized(self):
        """Test that unauthenticated requests are rejected"""
        data = {
            'title': 'Test',
            'cards': [{"question": "Q", "answer": "A"}]
        }
        
        response = self.client.post(self.save_url, data, content_type='application/json')
        self.assertEqual(response.status_code, 401)
    
    def test_save_flashcards_no_cards_key(self):
        """Test that missing 'cards' key returns a 400 error"""
        data = {
            'title': 'Missing Cards',
            'original_text': 'Some text'
        }
        
        response = self.client.post(self.save_url, data, **self.auth_headers)
        self.assertEqual(response.status_code, 400)
    
    # ============= GET FLASHCARDS TESTS =============
    
    def test_get_user_flashcards_empty(self):
        """Test retrieving flashcards when none exist"""
        response = self.client.get(self.get_url, **self.auth_headers)
        
        self.assertEqual(response.status_code, 200)
        json_response = response.json()
        self.assertIn('flashcards', json_response)
        self.assertEqual(len(json_response['flashcards']), 0)
    
    def test_get_user_flashcards_with_data(self):
        """Test retrieving user's flashcard sets with their cards"""
        # Create test flashcard
        flashcard = Flashcard.objects.create(
            user=self.user,
            title='Test Flashcard Set',
            original_text='Original test text',
            subject_class='TestClass',
            year='2024'
        )
        
        # Create cards
        FlashcardCard.objects.create(
            flashcard=flashcard,
            question='Q1',
            answer='A1'
        )
        FlashcardCard.objects.create(
            flashcard=flashcard,
            question='Q2',
            answer='A2'
        )
        
        response = self.client.get(self.get_url, **self.auth_headers)
        
        self.assertEqual(response.status_code, 200)
        json_response = response.json()
        self.assertEqual(len(json_response['flashcards']), 1)
        
        fc_data = json_response['flashcards'][0]
        self.assertEqual(fc_data['title'], 'Test Flashcard Set')
        self.assertEqual(fc_data['total_cards'], 2)
        self.assertEqual(len(fc_data['cards']), 2)
        self.assertEqual(fc_data['subject_class'], 'TestClass')
    
    def test_get_user_flashcards_filter_by_subject_class(self):
        """Test filtering flashcards by subject_class"""
        # Create flashcards with different classes
        fc1 = Flashcard.objects.create(
            user=self.user,
            title='Physics Set',
            subject_class='Physics 101'
        )
        fc2 = Flashcard.objects.create(
            user=self.user,
            title='Chemistry Set',
            subject_class='Chemistry 101'
        )
        
        params = {'subject_class': 'Physics 101'}
        response = self.client.get(self.get_url, params, **self.auth_headers)
        
        self.assertEqual(response.status_code, 200)
        json_response = response.json()
        self.assertEqual(len(json_response['flashcards']), 1)
        self.assertEqual(json_response['flashcards'][0]['subject_class'], 'Physics 101')
    
    def test_get_user_flashcards_filter_by_year(self):
        """Test filtering flashcards by year"""
        fc1 = Flashcard.objects.create(
            user=self.user,
            title='2023 Set',
            year='2023'
        )
        fc2 = Flashcard.objects.create(
            user=self.user,
            title='2024 Set',
            year='2024'
        )
        
        params = {'year': '2024'}
        response = self.client.get(self.get_url, params, **self.auth_headers)
        
        self.assertEqual(response.status_code, 200)
        json_response = response.json()
        self.assertEqual(len(json_response['flashcards']), 1)
        self.assertEqual(json_response['flashcards'][0]['year'], '2024')
    
    def test_get_user_flashcards_other_user_not_visible(self):
        """Test that flashcards from other users are not visible"""
        other_user = User.objects.create_user(username='other', password='pass123')
        
        fc1 = Flashcard.objects.create(
            user=self.user,
            title='My Set'
        )
        fc2 = Flashcard.objects.create(
            user=other_user,
            title='Other User Set'
        )
        
        response = self.client.get(self.get_url, **self.auth_headers)
        
        self.assertEqual(response.status_code, 200)
        json_response = response.json()
        self.assertEqual(len(json_response['flashcards']), 1)
        self.assertEqual(json_response['flashcards'][0]['title'], 'My Set')
    
    # ============= FILTER OPTIONS TESTS =============
    
    def test_get_flashcard_filter_options_empty(self):
        """Test getting filter options when no flashcards exist"""
        response = self.client.get(self.filter_options_url, **self.auth_headers)
        
        self.assertEqual(response.status_code, 200)
        json_response = response.json()
        self.assertEqual(json_response['classes'], [])
        self.assertEqual(json_response['years'], [])
    
    def test_get_flashcard_filter_options_with_data(self):
        """Test retrieving available filter options from user's flashcards"""
        Flashcard.objects.create(
            user=self.user,
            title='Bio',
            subject_class='Biology 101',
            year='2023'
        )
        Flashcard.objects.create(
            user=self.user,
            title='Chem',
            subject_class='Chemistry 101',
            year='2024'
        )
        Flashcard.objects.create(
            user=self.user,
            title='Physics',
            subject_class='Physics 101',
            year='2024'
        )
        
        response = self.client.get(self.filter_options_url, **self.auth_headers)
        
        self.assertEqual(response.status_code, 200)
        json_response = response.json()
        self.assertEqual(len(json_response['classes']), 3)
        self.assertEqual(len(json_response['years']), 2)
        self.assertIn('Biology 101', json_response['classes'])
        self.assertIn('2023', json_response['years'])
    
    # ============= DELETE FLASHCARDS TESTS =============
    
    def test_delete_flashcards_success(self):
        """Test successful deletion of a flashcard set"""
        flashcard = Flashcard.objects.create(
            user=self.user,
            title='To Delete'
        )
        
        delete_url = reverse('delete_flashcards', kwargs={'flashcard_id': flashcard.id})
        response = self.client.delete(delete_url, **self.auth_headers)
        
        self.assertEqual(response.status_code, 200)
        self.assertIn('message', response.json())
        
        # Verify it was deleted
        self.assertFalse(Flashcard.objects.filter(id=flashcard.id).exists())
    
    def test_delete_flashcards_not_found(self):
        """Test deleting non-existent flashcard returns 404"""
        delete_url = reverse('delete_flashcards', kwargs={'flashcard_id': 99999})
        response = self.client.delete(delete_url, **self.auth_headers)
        
        self.assertEqual(response.status_code, 404)
        self.assertIn('error', response.json())
    
    def test_delete_flashcards_unauthorized(self):
        """Test that users can't delete other users' flashcards"""
        other_user = User.objects.create_user(username='other', password='pass123')
        flashcard = Flashcard.objects.create(
            user=other_user,
            title='Others Flashcard'
        )
        
        delete_url = reverse('delete_flashcards', kwargs={'flashcard_id': flashcard.id})
        response = self.client.delete(delete_url, **self.auth_headers)
        
        self.assertEqual(response.status_code, 404)
        
        # Verify it still exists
        self.assertTrue(Flashcard.objects.filter(id=flashcard.id).exists())