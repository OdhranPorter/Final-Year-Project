# Architecture

## System Design

```
┌─────────────┐
│  Flutter    │
│ Mobile App  │
└──────┬──────┘
       │ HTTPS
       ▼
┌─────────────────────┐
│  Django REST API    │ ← Gemini AI
│  • Auth (JWT)       │ ← ML Kit (OCR)
│  • Summaries        │
│  • Quizzes          │
│  • Flashcards       │
└──────┬──────────────┘
       │
       ▼
   PostgreSQL
```

## Database Models

**User** - Django built-in  
**Note** - summaries with metadata  
**Quiz** - quiz attempts & scoring  
**Question** - quiz questions  
**QuestionOption** - answer choices  
**Flashcard** - flashcard sets  
**FlashcardCard** - individual cards  

## API Design

- RESTful with JSON
- JWT authentication
- Error responses with status codes
- Filtering by subject_class & year

## Tech Stack

| Component | Technology |
|-----------|-----------|
| Frontend | Flutter 3.10+ |
| Backend | Django 6.0 + DRF |
| AI | Google Gemini API |
| OCR | Google ML Kit |
| Database | PostgreSQL |
| Auth | JWT Tokens |

