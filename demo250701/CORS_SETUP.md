# Firebase Storage CORS Configuration

To enable image uploads and display for web platforms, you need to configure CORS for your Firebase Storage bucket.

## Prerequisites
1. Install Google Cloud SDK (`gcloud`)
2. Run `gcloud auth login` to authenticate

## Configuration Steps

1. **Set up gcloud for your project**:
   ```bash
   gcloud config set project yeskitest2
   ```

2. **Apply CORS configuration**:
   ```bash
   gsutil cors set cors.json gs://yeskitest2.firebasestorage.app
   ```

3. **Verify CORS configuration**:
   ```bash
   gsutil cors get gs://yeskitest2.firebasestorage.app
   ```

## CORS Configuration Details

The `cors.json` file specifically allows:
- **Your localhost:50000** (explicitly configured)
- **Origins**: Local development servers and Firebase hosting domains
- **Methods**: GET, POST, PUT, DELETE, HEAD, OPTIONS
- **Headers**: Content-Type, Authorization, X-Requested-With
- **Max Age**: 3600 seconds (1 hour)

## Testing CORS Configuration

### Quick Browser Test
1. Open your browser's Developer Console (F12)
2. Navigate to `http://localhost:50000` (your Flutter web app)
3. Run this JavaScript command in the console:

```javascript
// Test CORS with a sample Firebase Storage URL
fetch('https://firebasestorage.googleapis.com/v0/b/yeskitest2.firebasestorage.app/o/test-image.jpg?alt=media', {
  method: 'GET',
  mode: 'cors'
})
.then(response => {
  if (response.ok) {
    console.log('✅ CORS is working! Status:', response.status);
  } else {
    console.log('❌ HTTP Error:', response.status);
  }
})
.catch(error => {
  console.log('❌ CORS Error:', error);
  if (error.toString().includes('CORS')) {
    console.log('🔧 CORS is not configured properly');
  }
});
```

### Flutter App Testing
You can add the CORS test widget to any screen temporarily:

```dart
// Add this to any screen for testing
import '../widgets/cors_test_widget.dart';

// Then add to your widget tree
CorsTestWidget(),
```

### Manual Image Test
1. Upload any image to Firebase Storage through Firebase Console
2. Get the download URL
3. Try to display it in your Flutter web app using `Image.network(url)`
4. Check browser console for CORS errors

## Current Configuration Status

Your `cors.json` is configured for:
- `http://localhost:50000` ✅ (your current setup)
- `https://localhost:50000` ✅ (in case you use HTTPS)
- Wildcard localhost ports ✅ (backup)
- Firebase hosting domains ✅

## Troubleshooting

### Common Issues:

1. **"Access blocked by CORS policy"**
   ```bash
   # Reapply CORS configuration
   gsutil cors set cors.json gs://yeskitest2.firebasestorage.app
   ```

2. **Changes not taking effect**
   - Clear browser cache (Ctrl+Shift+R)
   - Try incognito/private browsing
   - Wait a few minutes for propagation

3. **Verify current CORS settings**
   ```bash
   gsutil cors get gs://yeskitest2.firebasestorage.app
   ```

4. **Check your current origin**
   Open browser console and run:
   ```javascript
   console.log('Current origin:', window.location.origin);
   ```

### If CORS still doesn't work:

1. **Double-check project ID**: Make sure you're using the correct Firebase project
2. **Check Firebase Storage Rules**: Ensure they allow read access
3. **Test with a different browser**: Sometimes browser settings can interfere
4. **Verify bucket name**: `gs://yeskitest2.firebasestorage.app`

## Firebase Storage Rules

Make sure your Firebase Storage rules allow reading:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read: if true; // Allow reading for testing
      allow write: if request.auth != null; // Only authenticated users can write
    }
  }
}
```