#!/bin/bash

echo "🔒 Firebase Storage Security Rules Check"
echo "========================================"

PROJECT_ID="yeskitest2"

echo "📋 Project: $PROJECT_ID"
echo ""

# Set project
echo "🔧 Setting gcloud project..."
gcloud config set project $PROJECT_ID

echo ""
echo "🛡️ Current Storage Security Rules:"
echo "To check your current storage rules:"
echo "1. Visit: https://console.firebase.google.com/project/$PROJECT_ID/storage/rules"
echo "2. Or run: firebase storage:rules:get --project $PROJECT_ID (if Firebase CLI is installed)"
echo ""

echo "📝 Recommended rules for testing (storage.rules file):"
echo "rules_version = '2';"
echo "service firebase.storage {"
echo "  match /b/{bucket}/o {"
echo "    match /{allPaths=**} {"
echo "      allow read: if true;"
echo "      allow write: if request.auth != null;"
echo "    }"
echo "  }"
echo "}"
echo ""

echo "⚠️ These are permissive rules for testing."
echo "In production, use more restrictive rules like:"
echo "    match /posts/{userId}/{postId}/{fileName} {"  
echo "      allow read: if true;"
echo "      allow write: if request.auth != null && request.auth.uid == userId;"
echo "    }"
echo ""

echo "🔗 Quick links:"
echo "- Firebase Console: https://console.firebase.google.com/project/$PROJECT_ID"
echo "- Storage Rules: https://console.firebase.google.com/project/$PROJECT_ID/storage/rules"
echo "- Authentication: https://console.firebase.google.com/project/$PROJECT_ID/authentication/users"