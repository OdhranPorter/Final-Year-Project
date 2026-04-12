@echo off
REM Deploy documentation to GitHub Pages (Windows version)
REM This script commits documentation changes and pushes to GitHub

setlocal enabledelayedexpansion

echo.
echo 🚀 StudiBro Documentation Deployment
echo ====================================
echo.

REM Check if git is available
git --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Git is not installed. Please install Git first.
    exit /b 1
)

REM Check if we're in a git repository
if not exist .git (
    echo ❌ Not in a git repository. Please run this from the project root.
    exit /b 1
)

echo 📝 Documentation changes detected
echo ===================================
echo.

REM Show what's changed
git status docs/ --short
git status _config.yml --short

echo.
echo ---
echo.

REM Ask for confirmation
set /p CONFIRM="Continue with deployment? (y/n): "
if /i not "%CONFIRM%"=="y" (
    echo Deployment cancelled.
    exit /b 0
)

echo.
echo 📦 Staging documentation files...
git add docs/
git add _config.yml

REM Get current timestamp
for /f "tokens=2-4 delims=/ " %%a in ('date /t') do (set mydate=%%c-%%a-%%b)
for /f "tokens=1-2 delims=/:" %%a in ('time /t') do (set mytime=%%a:%%b)

echo 💌 Committing changes...
git commit -m "docs: update documentation - %mydate% %mytime%"

echo 📤 Pushing to GitHub...
git push origin main

echo.
echo ✅ Documentation deployment complete!
echo.
echo 📍 Your documentation will be available at:
echo    https://yourusername.github.io/Final-Year-Project
echo.
echo ⏱️  It may take 1-2 minutes for changes to appear.
echo.
echo 🔗 Popular pages:
echo    - Home: /
echo    - Getting Started: /getting-started/
echo    - API Docs: /api-documentation/
echo    - Architecture: /architecture/
echo.
echo 💡 Tips:
echo    - Check GitHub Pages settings: Settings —> Pages
echo    - Verify source is set to 'main' branch, '/docs' folder
echo    - Enable GitHub Pages if not done already
echo.
pause
