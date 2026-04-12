# Getting Started

## 🔧 Backend Setup

```bash
cd backend
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt
```

Create `.env`:
```
GEMINI_API_KEY=your_key_here
DEBUG=True
SECRET_KEY=dev-key
```

Run:
```bash
python manage.py migrate
python manage.py runserver 0.0.0.0:8000
```

## 📱 Frontend Setup

```bash
cd frontend/studibro_mobile
flutter pub get
# Edit lib/config.dart with backend IP
flutter run
```

## Quick Troubleshooting

| Issue | Solution |
|-------|----------|
| Port 8000 in use | `lsof -ti:8000 \| xargs kill -9` |
| App can't connect | Check IP in config.dart |
| API Key error | Verify .env file |

