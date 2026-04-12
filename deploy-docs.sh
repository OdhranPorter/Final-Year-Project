#!/bin/bash
# Deploy documentation to GitHub Pages
# This script commits documentation changes and pushes to GitHub

set -e

echo "🚀 StudiBro Documentation Deployment"
echo "===================================="
echo ""

# Check if git is available
if ! command -v git &> /dev/null; then
    echo "❌ Git is not installed. Please install Git first."
    exit 1
fi

# Check if we're in a git repository
if [ ! -d .git ]; then
    echo "❌ Not in a git repository. Please run this from the project root."
    exit 1
fi

echo "📝 Documentation changes to commit:"
echo ""

# Show what's changed in docs folder
if git diff --quiet docs/; then
    echo "No changes detected in docs/ folder."
else
    echo "Changes detected:"
    git diff docs/ --name-only
fi

echo ""
echo "---"
echo ""

# Ask for confirmation
read -p "Continue with deployment? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Deployment cancelled."
    exit 1
fi

# Stage documentation files
echo "📦 Staging documentation files..."
git add docs/
git add _config.yml

# Commit changes
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
git commit -m "docs: update documentation - $TIMESTAMP" || echo "No changes to commit"

# Push to GitHub
echo "📤 Pushing to GitHub..."
git push origin main

echo ""
echo "✅ Documentation deployment complete!"
echo ""
echo "📍 Your documentation will be available at:"
echo "   https://yourusername.github.io/Final-Year-Project"
echo ""
echo "⏱️  It may take 1-2 minutes for changes to appear."
echo ""
echo "🔗 Popular pages:"
echo "   - Home: /"
echo "   - Getting Started: /getting-started/"
echo "   - API Docs: /api-documentation/"
echo "   - Architecture: /architecture/"
echo ""
echo "💡 Tips:"
echo "   - Check GitHub Pages settings: Settings → Pages"
echo "   - Verify source is set to 'main' branch, '/docs' folder"
echo "   - Enable GitHub Pages if not done already"
echo ""
