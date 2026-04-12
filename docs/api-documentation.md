# API Reference

**Base URL:** `http://localhost:8000/api`  
**Auth:** Include `Authorization: Bearer TOKEN` in all requests

## Authentication

### Register
```bash
POST /api/register/
{
  "username": "user",
  "email": "email@example.com",
  "password": "password"
}
```

### Get Token
```bash
POST /api/token/
{
  "username": "user",
  "password": "password"
}
```

## Summaries

```bash
# Generate
POST /api/summarize/
{ "text": "your notes..." }

# Save
POST /api/notes/save/
{
  "original_text": "notes",
  "summary_text": "summary",
  "subject_class": "Computer Science",
  "year": "2026"
}

# Get All
GET /api/notes/

# Delete
DELETE /api/notes/{id}/delete/
```

## Quizzes

```bash
# Generate
POST /api/generate-quiz/
{ "text": "notes..." }

# Save Results
POST /api/quizzes/
{
  "title": "Quiz 1",
  "questions": [...],
  ...
}

# Get History
GET /api/quizzes-history/

# Delete
DELETE /api/quizzes-history/{id}/delete/
```

## Flashcards

```bash
# Generate
POST /api/generate-flashcards/
{ "text": "notes..." }

# Save
POST /api/flashcards/
{
  "title": "Cards",
  "cards": [...]
}

# Get History
GET /api/flashcards-history/

# Delete
DELETE /api/flashcards/{id}/delete/
```

