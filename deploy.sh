#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "🚀 Starting deployment to GitHub..."

# Check if git is initialized
if [ ! -d .git ]; then
  echo "❌ Git is not initialized in this directory. Initializing..."
  git init
  git branch -M main
fi

# Check if remote 'origin' is configured
if ! git remote get-url origin >/dev/null 2>&1; then
  echo "⚠️  No git remote 'origin' is configured."
  echo "Please run: git remote add origin <your-github-repo-url>"
  echo "Then run this deploy script again."
  exit 1
fi

# Get current status
STATUS=$(git status --porcelain)
if [ -z "$STATUS" ]; then
  echo "✅ No changes to deploy. Everything is up to date!"
  exit 0
fi

# Add all changes
git add -A

# Get commit message from argument, or default
COMMIT_MSG=$1
if [ -z "$COMMIT_MSG" ]; then
  COMMIT_MSG="Update: Auto-deploy - $(date '+%Y-%m-%d %H:%M:%S')"
fi

# Commit
git commit -m "$COMMIT_MSG"

# Push to origin main
echo "📤 Pushing changes to GitHub (main)..."
git push origin main

echo "🎉 Deployment successful!"
