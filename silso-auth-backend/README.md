# Silso Authentication Backend Server

Backend server for Silso app authentication with Kakao and Firebase integration.

## 🚀 Quick Start

### Prerequisites
- Node.js 18+ installed
- npm 8+ installed
- Firebase project set up
- Kakao developer account and app configured

### Installation

1. **Install dependencies:**
   ```bash
   npm install
   ```

2. **Configure environment variables:**
   ```bash
   cp .env.example .env
   ```
   
   Edit `.env` file with your actual values:
   ```env
   FIREBASE_PROJECT_ID=your-firebase-project-id
   KAKAO_REST_API_KEY=your-kakao-rest-api-key
   KAKAO_CLIENT_SECRET=your-kakao-client-secret
   ```

3. **Add Firebase service account key:**
   - Download `firebase-service-account.json` from Firebase Console
   - Place it in the project root directory
   - **Never commit this file to version control!**

4. **Start the server:**
   ```bash
   # Development mode (auto-restart on changes)
   npm run dev
   
   # Production mode
   npm start
   ```

## 📡 API Endpoints

### Health Check
```http
GET /health
```
Returns server status and basic information.

### API Information
```http
GET /api/info
```
Returns available endpoints and API information.

### Kakao Authentication
```http
POST /auth/kakao/custom-token
Content-Type: application/json

{
  "kakao_access_token": "your-kakao-access-token"
}
```

**Success Response (200):**
```json
{
  "success": true,
  "firebase_custom_token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user_info": {
    "uid": "123456789",
    "email": "user@example.com",
    "name": "User Name",
    "picture": "https://...",
    "provider": "kakao",
    "kakao_id": 123456789,
    "email_verified": true,
    "has_email": true
  },
  "processing_time_ms": 245,
  "timestamp": "2024-01-15T10:30:00.000Z"
}
```

**Error Response (400/401/500):**
```json
{
  "error": "Error Type",
  "message": "Error description",
  "code": "ERROR_CODE",
  "processing_time_ms": 123
}
```

## 🔧 Configuration

### Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `PORT` | Server port (default: 3001) | No |
| `NODE_ENV` | Environment (development/production) | No |
| `FIREBASE_PROJECT_ID` | Firebase project ID | Yes |
| `FIREBASE_SERVICE_ACCOUNT_PATH` | Path to service account JSON | Yes |
| `KAKAO_REST_API_KEY` | Kakao REST API key | Yes |
| `KAKAO_CLIENT_SECRET` | Kakao client secret | Yes |
| `CORS_ORIGINS` | Allowed CORS origins (comma-separated) | No |
| `JWT_SECRET` | JWT secret for security | No |
| `LOG_LEVEL` | Logging level (info/debug/error) | No |

### CORS Configuration

By default, the server allows requests from:
- `http://localhost:3000` (Flutter web development)
- Any domains specified in `CORS_ORIGINS` environment variable

For production, update `CORS_ORIGINS`:
```env
CORS_ORIGINS=https://yourdomain.com,https://www.yourdomain.com
```

### Rate Limiting

- **Authentication endpoints**: 10 requests per 15 minutes per IP
- **General endpoints**: 100 requests per 15 minutes per IP

## 🔒 Security Features

- **Helmet.js**: Security headers
- **Rate limiting**: Prevents abuse
- **CORS protection**: Restricts origins
- **Input validation**: Validates all inputs
- **Error handling**: Doesn't expose internal details
- **Logging**: Comprehensive request logging

## 🧪 Testing

### Manual Testing

1. **Test health check:**
   ```bash
   curl http://localhost:3001/health
   ```

2. **Test with Kakao token:**
   ```bash
   curl -X POST http://localhost:3001/auth/kakao/custom-token \
     -H "Content-Type: application/json" \
     -d '{"kakao_access_token": "YOUR_KAKAO_ACCESS_TOKEN"}'
   ```

### Getting a Test Kakao Token

1. **Get authorization code:**
   Open in browser:
   ```
   https://kauth.kakao.com/oauth/authorize?client_id=YOUR_JAVASCRIPT_KEY&redirect_uri=http://localhost:3001/test&response_type=code
   ```

2. **Exchange for access token:**
   ```bash
   curl -X POST "https://kauth.kakao.com/oauth/token" \
     -H "Content-Type: application/x-www-form-urlencoded" \
     -d "grant_type=authorization_code" \
     -d "client_id=YOUR_JAVASCRIPT_KEY" \
     -d "client_secret=YOUR_CLIENT_SECRET" \
     -d "redirect_uri=http://localhost:3001/test" \
     -d "code=AUTHORIZATION_CODE_FROM_REDIRECT"
   ```

## 🚀 Deployment

### Railway (Recommended)

1. **Install Railway CLI:**
   ```bash
   npm install -g @railway/cli
   ```

2. **Deploy:**
   ```bash
   railway login
   railway init
   railway up
   ```

3. **Set environment variables:**
   ```bash
   railway variables set FIREBASE_PROJECT_ID=your-project-id
   railway variables set KAKAO_REST_API_KEY=your-key
   railway variables set KAKAO_CLIENT_SECRET=your-secret
   ```

### Heroku

1. **Create app:**
   ```bash
   heroku create silso-auth-backend
   ```

2. **Set environment variables:**
   ```bash
   heroku config:set FIREBASE_PROJECT_ID=your-project-id
   heroku config:set KAKAO_REST_API_KEY=your-key
   heroku config:set KAKAO_CLIENT_SECRET=your-secret
   ```

3. **Deploy:**
   ```bash
   git push heroku main
   ```

### Vercel

1. **Install Vercel CLI:**
   ```bash
   npm install -g vercel
   ```

2. **Deploy:**
   ```bash
   vercel
   ```

## 🔍 Troubleshooting

### Common Issues

**Firebase Admin SDK initialization failed:**
- Ensure `firebase-service-account.json` is in the project root
- Check that the file path in `.env` is correct
- Verify the service account has proper permissions

**Kakao API errors:**
- Verify your Kakao REST API key is correct
- Check that your Kakao app configuration matches
- Ensure the access token is valid and not expired

**CORS errors:**
- Add your Flutter app's URL to `CORS_ORIGINS`
- For local development, include `http://localhost:3000`

**Rate limiting errors:**
- Wait for the rate limit window to reset (15 minutes)
- Consider implementing exponential backoff in your client

### Logs

The server provides detailed logging:
- ✅ Success operations
- ❌ Error conditions  
- 🟡 Processing steps
- 📡 Request information

Monitor logs to debug issues:
```bash
# Development
npm run dev

# Production with PM2
pm2 logs silso-auth-backend
```

## 📚 API Flow

1. **Flutter app** → User taps "Login with Kakao"
2. **Kakao SDK** → Returns access token to Flutter app
3. **Flutter app** → Sends access token to this backend server
4. **Backend server** → Verifies token with Kakao API
5. **Backend server** → Creates Firebase custom token
6. **Backend server** → Returns custom token to Flutter app
7. **Flutter app** → Uses custom token to sign into Firebase

## 🔗 Related Documentation

- [Kakao Login API](https://developers.kakao.com/docs/latest/en/kakaologin/rest-api)
- [Firebase Custom Tokens](https://firebase.google.com/docs/auth/admin/create-custom-tokens)
- [Express.js Documentation](https://expressjs.com/)

## 📄 License

ISC License - see LICENSE file for details.

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📞 Support

For issues and questions:
1. Check the troubleshooting section above
2. Review server logs for detailed error information
3. Ensure all configuration steps are completed correctly