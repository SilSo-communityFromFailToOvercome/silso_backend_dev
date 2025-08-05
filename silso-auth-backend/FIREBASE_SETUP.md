# Firebase Service Account Setup

## 📋 Steps to Complete Firebase Configuration

### 1. Get Your Firebase Service Account Key

1. **Go to Firebase Console:**
   - Visit: https://console.firebase.google.com
   - Select your project: `silso-mvp-1-0`

2. **Navigate to Service Accounts:**
   - Click the gear icon (⚙️) → Project Settings
   - Click on "Service accounts" tab
   - You should see "Firebase Admin SDK" section

3. **Generate New Private Key:**
   - Click "Generate new private key" button
   - A dialog will appear warning about keeping the key secure
   - Click "Generate key"
   - A JSON file will be downloaded

4. **Rename and Place the File:**
   - Rename the downloaded file to: `firebase-service-account.json`
   - Move it to this directory: `/Users/yeski/Documents/Silso_MVP_1.0/silso-auth-backend/`
   - The file should be in the same folder as `server.js`

### 2. Update Environment Variables

Edit the `.env` file in this directory and update:

```env
# Replace with your actual Firebase project ID
FIREBASE_PROJECT_ID=silso-mvp-1-0

# Replace with your actual Kakao keys from Kakao Developer Console
KAKAO_REST_API_KEY=your-actual-kakao-rest-api-key
KAKAO_CLIENT_SECRET=your-actual-kakao-client-secret
```

### 3. Security Check

Make sure the service account file is in `.gitignore`:
- ✅ `firebase-service-account.json` should be listed in `.gitignore`
- ✅ **NEVER commit this file to version control**
- ✅ Keep this file secure and private

### 4. Test the Server

After placing the Firebase service account file:

```bash
# Start the server
npm run dev

# Test health check
curl http://localhost:3001/health
```

You should see:
```
🚀 ================================
🚀 Silso Auth Backend Server Started
🚀 ================================
📡 Server running on port: 3001
🔥 Firebase Project: silso-mvp-1-0
🟡 Kakao Integration: Ready
🌍 Environment: development
🔒 Rate Limiting: Enabled
⏰ Started at: [timestamp]
🚀 ================================
```

## 🔍 Troubleshooting

### "Cannot find module './firebase-service-account.json'"
- Make sure you downloaded the service account key from Firebase Console
- Ensure the file is named exactly: `firebase-service-account.json`
- Check that the file is in the same directory as `server.js`

### "Firebase Admin SDK initialization failed"
- Verify the JSON file is valid (open it and check it's proper JSON)
- Ensure your Firebase project ID matches in both the file and `.env`
- Check that the service account has proper permissions

### Next Steps After Setup

Once the backend server is running successfully:
1. ✅ Firebase service account configured
2. ✅ Server starts without errors
3. ✅ Health check responds correctly
4. 🔄 **Next**: Configure Kakao keys and test Kakao authentication
5. 🔄 **Then**: Implement Kakao login in your Flutter app