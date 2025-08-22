# Backend Connection Configuration Guide

## ✅ Fixed: "No route to host" Backend Connection Error

The issue was caused by an incorrect IP address configuration in the mobile app.

### What Was Fixed:
- **Updated IP address** from `172.18.142.109` to `172.17.204.251` (current machine IP)
- **Added flexible configuration** options for different development scenarios
- **Backend server confirmed running** on `localhost:3001`

### Current Configuration:
- **Backend Server**: Running on `http://localhost:3001` ✅
- **Mobile App**: Connecting to `http://172.17.204.251:3001` ✅
- **Health Check**: `curl http://172.17.204.251:3001/health` ✅

### Configuration Options in `korean_auth_service_mobile.dart`:

```dart
static String get _backendUrl {
  // Option 1: Emulator (10.0.2.2 maps to localhost on host)
  // return 'http://10.0.2.2:3001';
  
  // Option 2: Real device (your computer's IP on local network)
  return 'http://172.17.204.251:3001';
  
  // Option 3: Production server URL
  // return 'https://your-production-server.com';
}
```

### Quick Setup for Different Scenarios:

#### 🔧 For Android Emulator:
```dart
return 'http://10.0.2.2:3001';
```

#### 📱 For Real Android Device:
```dart
return 'http://172.17.204.251:3001';  // Your computer's IP
```

#### 🌐 For Production:
```dart
return 'https://your-production-server.com';
```

### How to Find Your Computer's IP:
```bash
# macOS/Linux
ifconfig | grep "inet " | grep -v 127.0.0.1

# Windows
ipconfig | findstr "IPv4"
```

### Testing Backend Connection:
```bash
# Test backend health
curl http://172.17.204.251:3001/health

# Expected response:
{
  "status": "OK",
  "service": "Silso Auth Backend",
  "version": "1.0.0"
}
```

### Backend Server Status:
- ✅ **Server Running**: Port 3001
- ✅ **Firebase Admin SDK**: Initialized
- ✅ **Kakao Integration**: Ready
- ✅ **Health Endpoint**: `/health`
- ✅ **Auth Endpoint**: `/auth/kakao/custom-token`

### Next Steps:
1. **Clean rebuild** the Flutter app:
   ```bash
   cd demo250822
   flutter clean
   flutter pub get
   flutter run
   ```

2. **Test Kakao login** - should now connect to backend successfully

The app should now connect to the backend server without "No route to host" errors!