# Railway Deployment Checklist

## ✅ Backend Preparation (DONE)
- [x] Updated Django settings.py for production
- [x] Created Procfile for Railway
- [x] Added requirements.txt dependencies (gunicorn, psycopg2, dj-database-url, whitenoise)
- [x] Created .env with SECRET_KEY: `yib%socz7rlkbed#g$3r0$2m$it%km349z2cwxxbyw3ssupehx`

## 📋 NEXT STEPS - Follow in Order

### Step 1: Get Your Gemini API Key (2 minutes)
**ACTION:** Go to https://makersuite.google.com/app/apikeys
- Sign in with your Google account
- Click "Create API Key" or copy existing key
- Copy the key

**THEN:** Update your .env file:
```
GEMINI_API_KEY=paste-your-key-here
```

### Step 2: Push Code to GitHub (5 minutes)
**ACTION:** In terminal:
```powershell
cd C:\Users\odhra\Documents\GitHub\Final-Year-Project
git add .
git commit -m "Configure backend for Railway deployment"
git push origin main
```

### Step 3: Deploy Backend to Railway (10 minutes)
**ACTION:** 
1. Go to https://railway.app
2. Sign in (use GitHub to sign up if needed)
3. Click "New Project"
4. Select "Deploy from GitHub"
5. Pick "Final-Year-Project" repo
6. Select the `/backend` directory when prompted
7. Railway will auto-detect Procfile and start building

**Wait for deployment to complete (look for green checkmark)**

### Step 4: Add Environment Variables to Railway (5 minutes)
**ACTION:** In Railway dashboard:
1. Go to your project → Variables tab
2. Add these variables:
   - `DEBUG` = `False`
   - `SECRET_KEY` = `yib%socz7rlkbed#g$3r0$2m$it%km349z2cwxxbyw3ssupehx` (copy from .env)
   - `GEMINI_API_KEY` = (paste the key from Step 1)

3. **DO NOT manually add DATABASE_URL** - Railway will auto-generate it when you add PostgreSQL

### Step 5: Add PostgreSQL to Railway (5 minutes)
**ACTION:**
1. In Railway dashboard, click "Add a service"
2. Select "PostgreSQL"
3. Wait for it to provision
4. Railway auto-adds `DATABASE_URL` environment variable ✅

### Step 6: Deploy (Automatic!)
Railway will automatically redeploy your app with the new environment variables.
**Wait for green checkmark** ✅

### Step 7: Get Your Railway URL
**ACTION:** In Railway dashboard:
1. Go to your project
2. Find "Domain" or "URL" section
3. Copy your URL (looks like: `https://studibro-production.up.railway.app`)
4. **SAVE THIS URL** - you'll need it for the Flutter app

### Step 8: Test the Backend
**ACTION:** Open a browser and visit:
```
https://your-railway-url/api/health/
```
You should see a response (might be blank or 200 OK)

## 🚀 Final Step: Update & Build Flutter APK

Once you have your Railway URL from Step 7:

1. Open Flutter app file: `frontend/studibro_mobile/lib/config.dart`
2. Find this line:
   ```dart
   const String API_URL = 'http://192.168.0.8:8000';
   ```
3. Replace it with:
   ```dart
   const String API_URL = 'https://your-railway-url';
   ```

4. In terminal, build APK:
   ```powershell
   cd frontend/studibro_mobile
   flutter build apk --release
   ```

5. APK will be at: `build/app/outputs/flutter-app.apk`

6. Share the APK with your friends! ✅

---

## 📍 Current Status
- Backend: ✅ Ready to deploy
- Gemini API Key: ⏳ Need to add
- GitHub Push: ⏳ Pending
- Railway Setup: ⏳ Pending
- Flutter APK: ⏳ Will do after Railway is live
