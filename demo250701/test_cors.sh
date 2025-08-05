#!/bin/bash

echo "🧪 Firebase Storage CORS Test Script"
echo "======================================"

# Check if gsutil is installed
if ! command -v gsutil &> /dev/null; then
    echo "❌ gsutil is not installed. Please install Google Cloud SDK first."
    echo "   Visit: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Check if gcloud is authenticated
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q "."; then
    echo "❌ Not authenticated with gcloud. Please run:"
    echo "   gcloud auth login"
    exit 1
fi

PROJECT_ID="yeskitest2"
BUCKET_NAME="yeskitest2.firebasestorage.app"

echo "📋 Project: $PROJECT_ID"
echo "📦 Bucket: gs://$BUCKET_NAME"
echo ""

# Set project
echo "🔧 Setting gcloud project..."
gcloud config set project $PROJECT_ID

# Apply CORS configuration
echo "🌐 Applying CORS configuration..."
if gsutil cors set cors.json gs://$BUCKET_NAME; then
    echo "✅ CORS configuration applied successfully!"
else
    echo "❌ Failed to apply CORS configuration"
    exit 1
fi

# Verify CORS configuration
echo ""
echo "🔍 Verifying CORS configuration..."
gsutil cors get gs://$BUCKET_NAME

echo ""
echo "✅ CORS configuration complete!"
echo ""
echo "🧪 Next steps to test:"
echo "1. Run your Flutter web app on http://localhost:50000"
echo "2. Open browser console (F12)"
echo "3. Run this JavaScript test:"
echo ""
echo "fetch('https://firebasestorage.googleapis.com/v0/b/$BUCKET_NAME/o/test-image.jpg?alt=media', {"
echo "  method: 'GET',"
echo "  mode: 'cors'"
echo "})"
echo ".then(r => console.log('✅ CORS working:', r.status))"
echo ".catch(e => console.log('❌ CORS error:', e));"
echo ""
echo "4. Try uploading an image in your Flutter app"
echo "5. Check browser console for any CORS errors"