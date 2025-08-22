#!/bin/bash

echo "🔑 Generating Kakao Android Hash Key"
echo "======================================"

# Debug keystore hash
echo "📱 DEBUG HASH KEY:"
keytool -exportcert -alias androiddebugkey -keystore ~/.android/debug.keystore -storepass android -keypass android | openssl sha1 -binary | openssl base64

echo ""
echo "📋 REGISTRATION INSTRUCTIONS:"
echo "1. Copy the hash key above"
echo "2. Go to Kakao Developers Console: https://developers.kakao.com/"
echo "3. Select your app: mvp (com.silso.mvp)"
echo "4. Go to 'Platform' → 'Android'"
echo "5. Add the hash key above"
echo "6. Make sure package name is: com.silso.mvp"
echo ""
echo "🔧 SHA1 Fingerprint (for reference):"
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android | grep SHA1

echo ""
echo "✅ Once registered, rebuild and test your app"