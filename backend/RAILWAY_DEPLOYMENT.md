# Railway Deployment Guide for StudiBro Backend

## Prerequisites
- Railway account (https://railway.app)
- GitHub account with your StudiBro repo

## Step 1: Add Required Packages

Your `requirements.txt` should include these packages. Update it with:
- `gunicorn` - Production WSGI server
- `dj-database-url` - Parse database URL from Railway
- `psycopg2-binary` - PostgreSQL adapter for Python
- `whitenoise` - Serve static files efficiently
- `python-decouple` - Load environment variables

## Step 2: Get Your Gemini API Key
1. Go to https://makersuite.google.com/app/apikeys
2. Create a new API key or copy your existing one
3. Save it for Step 4

## Step 3: Deploy to Railway
1. Go to railway.app and sign in
2. Click "New Project"
3. Select "Deploy from GitHub"
4. Choose your Final-Year-Project repository
5. Railway will auto-detect it's a Python/Django project

## Step 4: Add Environment Variables in Railway
In your Railway project dashboard, go to **Variables** and add:

```
DEBUG=False
SECRET_KEY=your-secret-key-here
GEMINI_API_KEY=your-gemini-api-key-here (from Step 2)
ALLOWED_HOSTS=your-railway-app.up.railway.app
CORS_ALLOWED_ORIGINS=https://your-railway-app.up.railway.app
```

To generate a secure SECRET_KEY, run in terminal:
```bash
python -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())"
```

## Step 5: Add PostgreSQL Database
1. In Railway dashboard, click "Add a service"
2. Select "PostgreSQL"
3. Railway will automatically create a `DATABASE_URL` environment variable
4. No need to add it manually - it's auto-populated

## Step 6: Deploy
Railway will auto-deploy when you:
- Push to your GitHub repo, OR
- Click "Deploy" in Railway dashboard

The Procfile will:
- Run migrations automatically: `python manage.py migrate`
- Start the Gunicorn server: `gunicorn studibro_project.wsgi`

## Step 7: Test Your API
Once deployed, your backend will be at:
`https://your-railway-app.up.railway.app`

Test a health check:
```bash
curl https://your-railway-app.up.railway.app/api/health/
```

## Step 8: Update Flutter App to Use Railway URL
In your Flutter app, replace the hardcoded IP:

**Before:**
```dart
const String API_URL = 'http://192.168.0.8:8000';
```

**After:**
```dart
const String API_URL = 'https://your-railway-app.up.railway.app';
```

Then rebuild your APK:
```bash
flutter build apk --release
```

## Troubleshooting

### App won't start?
Check logs in Railway dashboard → Deployments → View logs

### Database migration failed?
SSH into Railway container and run:
```bash
railway run python manage.py migrate --noinput
```

### CORS errors?
Make sure `CORS_ALLOWED_ORIGINS` includes your Railway app URL in the environment variables

### Static files not loading?
WhiteNoise is configured to handle this automatically

## Monitoring & Logs
- Railway Dashboard → Deployments → View logs
- Check response times, errors, and database queries
- Set up alerts for crashes

## Cost
- Railway free tier: $5 credit/month
- PostgreSQL: ~$100 GB data storage/month
- Generous free tier should be sufficient for MVP

## Next Steps After Deployment
1. ✅ Build Flutter APK: `flutter build apk --release`
2. ✅ Share APK file with friends
3. ✅ (Optional) Publish to Google Play Store for wider distribution
