# Deployment

## Heroku (Easiest)

```bash
heroku create study-app
heroku addons:create heroku-postgresql:hobby-dev
heroku config:set GEMINI_API_KEY=your_key
git push heroku main
heroku run python manage.py migrate
```

## AWS EC2

```bash
# Create Ubuntu instance
# SSH in and run:
sudo apt update
sudo apt install python3-pip nginx postgresql

# Clone repo & setup
git clone your-repo
cd backend
pip install -r requirements.txt
python manage.py migrate

# Setup Gunicorn + Nginx + SSL
# (See full deployment docs for details)
```

## Mobile Apps

**Android:**
```bash
cd frontend/studibro_mobile
flutter build apk --release
# Upload to Google Play
```

**iOS:**
```bash
flutter build ios --release
# Upload via Xcode/App Store Connect
```

## Environment Variables

```env
DEBUG=False
SECRET_KEY=production-key
GEMINI_API_KEY=your-key
DATABASE_URL=postgresql://...
ALLOWED_HOSTS=yourdomain.com
```

