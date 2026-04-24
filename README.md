# StudiBro: An AI Study Companion

**StudiBro** is a mobile application developed as a **Final Year Project** for the **BSc (Hons) in Computer Science** at **Atlantic Technological University (ATU)**.

StudiBro supports **Active Recall** by helping students convert unstructured notes into **summaries, quizzes, and flashcards**. It combines **on-device OCR** (Computer Vision) with a secure **client–server** backend for AI generation and data persistence.

> Final Year Project by **Odhran Porter**.

---

## Core Features

### OCR Note Capture + Editing (On-device)
- Capture notes using the device **camera** or **gallery**.
- Text is extracted locally using **Google ML Kit** OCR.
- OCR output is shown in an **editable text box** so users can correct extraction errors before generating study materials.

### AI Summaries (UI-ready + Safe Handling)
- Send validated text to the backend to generate concise summaries using the **Google Gemini API**.
- The backend returns structured responses suitable for rendering in the Flutter UI.
- Defensive handling is implemented to prevent crashes when AI output is malformed.

### Quiz + Flashcard Generation (Active Recall)
- Generate quizzes and flashcards from notes to support Active Recall Learning.
- Endpoints enforce required input and authentication, returning predictable JSON structures for the UI.

### Study History / Persistence
- Save and retrieve summaries, quiz attempts, and flashcard sets.
- View history and reuse generated study materials across sessions.

---

## System Architecture

StudiBro uses a **client–server architecture**:

- **Flutter mobile client (Dart):** UI, image capture, and on-device OCR.
- **Django REST API (Python):** JWT authentication, input validation, Gemini integration, and persistence.

This separation keeps API keys off the device and supports future extensibility (e.g., additional clients).

---

## Tech Stack

- **Frontend:** Flutter (Dart)
- **Backend:** Django REST Framework (Python)
- **Authentication:** JWT
- **Computer Vision (OCR):** Google ML Kit (on-device)
- **LLM:** Google Gemini API
- **Database:** SQLite (development) → PostgreSQL (deployment)

---

## Notes
- AI features require network access to the backend.
- OCR quality varies depending on lighting, focus, and handwriting style; manual correction is provided to mitigate this.
