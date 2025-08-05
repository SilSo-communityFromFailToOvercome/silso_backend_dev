const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const admin = require('firebase-admin');
const axios = require('axios');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3001;

// Initialize Firebase Admin SDK
let serviceAccount;
try {
  serviceAccount = require(process.env.FIREBASE_SERVICE_ACCOUNT_PATH);
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    projectId: process.env.FIREBASE_PROJECT_ID,
  });
  console.log('🔥 Firebase Admin SDK initialized successfully');
} catch (error) {
  console.error('❌ Firebase Admin SDK initialization failed:', error.message);
  console.log('💡 Make sure to place your firebase-service-account.json file in the project root');
  process.exit(1);
}

// Rate limiting for authentication endpoints
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 10, // limit each IP to 10 requests per windowMs
  message: {
    error: 'Too many authentication attempts',
    message: 'Please try again later (max 10 attempts per 15 minutes)'
  },
  standardHeaders: true,
  legacyHeaders: false,
});

// General rate limiting
const generalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  message: {
    error: 'Too many requests',
    message: 'Please try again later'
  }
});

// Middleware
app.use(helmet({
  crossOriginResourcePolicy: { policy: "cross-origin" }
}));

app.use(cors({
  origin: process.env.CORS_ORIGINS?.split(',') || ['http://localhost:3000'],
  credentials: true,
  methods: ['GET', 'POST', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));

app.use(generalLimiter);
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Logging middleware
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.path} - ${req.ip}`);
  next();
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ 
    status: 'OK', 
    timestamp: new Date().toISOString(),
    service: 'Silso Auth Backend',
    version: '1.0.0',
    environment: process.env.NODE_ENV || 'development'
  });
});

// API info endpoint
app.get('/api/info', (req, res) => {
  res.json({
    service: 'Silso Authentication Backend',
    version: '1.0.0',
    endpoints: [
      'GET /health - Health check',
      'GET /api/info - API information',
      'POST /auth/kakao/custom-token - Kakao authentication',
      'POST /auth/kakao/exchange-code - Exchange authorization code for access token'
    ],
    environment: process.env.NODE_ENV || 'development'
  });
});

// Apply auth rate limiting to authentication routes
app.use('/auth/', authLimiter);

// Kakao authentication endpoint
app.post('/auth/kakao/custom-token', async (req, res) => {
  const startTime = Date.now();
  
  try {
    const { kakao_access_token } = req.body;

    // Validate request
    if (!kakao_access_token) {
      return res.status(400).json({ 
        error: 'Bad Request',
        message: 'kakao_access_token is required',
        code: 'MISSING_ACCESS_TOKEN'
      });
    }

    if (typeof kakao_access_token !== 'string' || kakao_access_token.trim().length === 0) {
      return res.status(400).json({ 
        error: 'Bad Request',
        message: 'kakao_access_token must be a non-empty string',
        code: 'INVALID_ACCESS_TOKEN_FORMAT'
      });
    }

    console.log('🟡 Starting Kakao authentication process...');

    // Step 1: Verify Kakao access token and get user info
    const kakaoUserInfo = await getKakaoUserInfo(kakao_access_token);
    console.log('✅ Kakao user info retrieved successfully');
    
    // Step 2: Create Firebase custom token
    const customToken = await createFirebaseCustomToken(kakaoUserInfo);
    console.log('✅ Firebase custom token created successfully');
    
    // Step 3: Return the custom token with user info
    const processingTime = Date.now() - startTime;
    res.json({
      success: true,
      firebase_custom_token: customToken,
      user_info: {
        uid: kakaoUserInfo.id.toString(),
        email: kakaoUserInfo.kakao_account?.email || null,
        name: kakaoUserInfo.kakao_account?.profile?.nickname || null,
        picture: kakaoUserInfo.kakao_account?.profile?.profile_image_url || null,
        provider: 'kakao',
        kakao_id: kakaoUserInfo.id,
        email_verified: kakaoUserInfo.kakao_account?.email_valid || false,
        has_email: kakaoUserInfo.kakao_account?.has_email || false
      },
      processing_time_ms: processingTime,
      timestamp: new Date().toISOString()
    });

    console.log(`✅ Kakao authentication completed successfully in ${processingTime}ms`);

  } catch (error) {
    const processingTime = Date.now() - startTime;
    console.error('❌ Kakao auth error:', error.message);
    
    // Handle specific error types
    if (error.response?.status === 401) {
      return res.status(401).json({ 
        error: 'Unauthorized',
        message: 'Invalid or expired Kakao access token',
        code: 'INVALID_KAKAO_TOKEN',
        processing_time_ms: processingTime
      });
    }
    
    if (error.response?.status === 403) {
      return res.status(403).json({ 
        error: 'Forbidden',
        message: 'Kakao API access forbidden. Check your app configuration.',
        code: 'KAKAO_API_FORBIDDEN',
        processing_time_ms: processingTime
      });
    }

    if (error.code === 'NETWORK_ERROR') {
      return res.status(503).json({ 
        error: 'Service Unavailable',
        message: 'Unable to connect to Kakao servers',
        code: 'KAKAO_API_UNAVAILABLE',
        processing_time_ms: processingTime
      });
    }

    if (error.code === 'FIREBASE_ERROR') {
      return res.status(500).json({ 
        error: 'Internal Server Error',
        message: 'Firebase authentication failed',
        code: 'FIREBASE_TOKEN_CREATION_FAILED',
        processing_time_ms: processingTime
      });
    }
    
    // Generic error response
    res.status(500).json({ 
      error: 'Internal Server Error',
      message: 'Authentication failed. Please try again.',
      code: 'AUTHENTICATION_FAILED',
      processing_time_ms: processingTime
    });
  }
});

// Kakao authorization code exchange endpoint
app.post('/auth/kakao/exchange-code', async (req, res) => {
  const startTime = Date.now();
  
  try {
    const { authorization_code, redirect_uri } = req.body;

    // Validate request
    if (!authorization_code) {
      return res.status(400).json({ 
        error: 'Bad Request',
        message: 'authorization_code is required',
        code: 'MISSING_AUTHORIZATION_CODE'
      });
    }

    if (!redirect_uri) {
      return res.status(400).json({ 
        error: 'Bad Request',
        message: 'redirect_uri is required',
        code: 'MISSING_REDIRECT_URI'
      });
    }

    console.log('🟡 Exchanging Kakao authorization code for access token...');

    // Exchange authorization code for access token
    const accessToken = await exchangeKakaoCodeForToken(authorization_code, redirect_uri);
    console.log('✅ Kakao access token obtained successfully');
    
    // Return the access token (the frontend will use this with the existing custom-token endpoint)
    const processingTime = Date.now() - startTime;
    res.json({
      success: true,
      access_token: accessToken,
      processing_time_ms: processingTime,
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    const processingTime = Date.now() - startTime;
    console.error('❌ Kakao code exchange error:', error.message);
    
    if (error.response?.status === 400) {
      return res.status(400).json({ 
        error: 'Bad Request',
        message: 'Invalid authorization code or redirect URI',
        code: 'INVALID_AUTHORIZATION_CODE',
        processing_time_ms: processingTime
      });
    }
    
    if (error.response?.status === 401) {
      return res.status(401).json({ 
        error: 'Unauthorized',
        message: 'Invalid Kakao application credentials',
        code: 'KAKAO_AUTH_FAILED',
        processing_time_ms: processingTime
      });
    }
    
    // Generic error response
    res.status(500).json({ 
      error: 'Internal Server Error',
      message: 'Code exchange failed. Please try again.',
      code: 'CODE_EXCHANGE_FAILED',
      processing_time_ms: processingTime
    });
  }
});

// Function to exchange Kakao authorization code for access token
async function exchangeKakaoCodeForToken(authorizationCode, redirectUri) {
  try {
    console.log('🟡 Calling Kakao token endpoint...');
    
    const response = await axios.post('https://kauth.kakao.com/oauth/token', {
      grant_type: 'authorization_code',
      client_id: process.env.KAKAO_REST_API_KEY,
      client_secret: process.env.KAKAO_CLIENT_SECRET,
      code: authorizationCode,
      redirect_uri: redirectUri
    }, {
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded'
      },
      timeout: 10000 // 10 second timeout
    });
    
    console.log('✅ Kakao token response received');
    
    if (response.data.access_token) {
      return response.data.access_token;
    } else {
      throw new Error('No access token in Kakao response');
    }
  } catch (error) {
    console.error('❌ Kakao token exchange error:', error.response?.data || error.message);
    
    if (error.response?.status === 400) {
      throw new Error(`Invalid authorization code: ${error.response.data.error_description || error.response.data.error}`);
    }
    
    if (error.response?.status === 401) {
      throw new Error('Invalid Kakao application credentials');
    }
    
    throw new Error(`Kakao token exchange failed: ${error.message}`);
  }
}

// Function to get user info from Kakao
async function getKakaoUserInfo(accessToken) {
  try {
    // Handle demo token for testing
    if (accessToken === 'demo_kakao_access_token_for_testing') {
      console.log('🟡 Using DEMO Kakao user data for testing...');
      return {
        id: 99999999,
        connected_at: new Date().toISOString(),
        kakao_account: {
          profile_nickname_needs_agreement: false,
          profile_image_needs_agreement: false,
          profile: {
            nickname: 'Demo User',
            thumbnail_image_url: 'https://via.placeholder.com/64x64.png?text=Demo',
            profile_image_url: 'https://via.placeholder.com/256x256.png?text=Demo',
            is_default_image: true
          },
          has_email: true,
          email_needs_agreement: false,
          is_email_valid: true,
          is_email_verified: true,
          email: 'demo.user@kakao.demo'
        }
      };
    }
    
    console.log('🟡 Requesting user info from Kakao API...');
    
    const response = await axios.get('https://kapi.kakao.com/v2/user/me', {
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type': 'application/x-www-form-urlencoded;charset=utf-8'
      },
      timeout: 10000 // 10 second timeout
    });
    
    console.log('✅ Kakao API response received');
    return response.data;
  } catch (error) {
    console.error('❌ Kakao API error:', error.response?.data || error.message);
    
    if (error.code === 'ENOTFOUND' || error.code === 'ECONNREFUSED') {
      const networkError = new Error('Network error connecting to Kakao');
      networkError.code = 'NETWORK_ERROR';
      throw networkError;
    }
    
    if (error.response?.status === 401) {
      throw new Error('Invalid or expired Kakao access token');
    }
    
    if (error.response?.status === 403) {
      throw new Error('Kakao API access forbidden');
    }
    
    throw new Error(`Failed to get user info from Kakao: ${error.message}`);
  }
}

// Function to create Firebase custom token
async function createFirebaseCustomToken(kakaoUserInfo) {
  try {
    console.log('🟡 Creating Firebase custom token...');
    
    const uid = kakaoUserInfo.id.toString();
    
    // Additional claims to include in the token
    const additionalClaims = {
      provider: 'kakao',
      kakao_id: kakaoUserInfo.id,
      email: kakaoUserInfo.kakao_account?.email || null,
      nickname: kakaoUserInfo.kakao_account?.profile?.nickname || null,
      profile_image: kakaoUserInfo.kakao_account?.profile?.profile_image_url || null,
      verified_email: kakaoUserInfo.kakao_account?.email_valid || false,
      has_email: kakaoUserInfo.kakao_account?.has_email || false,
      created_at: new Date().toISOString()
    };

    // Create custom token
    const customToken = await admin.auth().createCustomToken(uid, additionalClaims);
    
    console.log('✅ Firebase custom token created');
    return customToken;
  } catch (error) {
    console.error('❌ Firebase custom token creation error:', error);
    const firebaseError = new Error(`Failed to create Firebase custom token: ${error.message}`);
    firebaseError.code = 'FIREBASE_ERROR';
    throw firebaseError;
  }
}

// Error handling middleware
app.use((error, req, res, next) => {
  console.error('❌ Unhandled error:', error);
  res.status(500).json({ 
    error: 'Internal Server Error',
    message: 'Something went wrong on our end',
    code: 'INTERNAL_ERROR'
  });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({ 
    error: 'Not Found',
    message: `Endpoint ${req.method} ${req.originalUrl} not found`,
    code: 'ENDPOINT_NOT_FOUND',
    available_endpoints: [
      'GET /health',
      'GET /api/info', 
      'POST /auth/kakao/custom-token'
    ]
  });
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('🔶 SIGTERM received, shutting down gracefully...');
  process.exit(0);
});

process.on('SIGINT', () => {
  console.log('🔶 SIGINT received, shutting down gracefully...');
  process.exit(0);
});

// Start server
app.listen(PORT, () => {
  console.log('🚀 ================================');
  console.log(`🚀 Silso Auth Backend Server Started`);
  console.log('🚀 ================================');
  console.log(`📡 Server running on port: ${PORT}`);
  console.log(`🔥 Firebase Project: ${process.env.FIREBASE_PROJECT_ID}`);
  console.log(`🟡 Kakao Integration: Ready`);
  console.log(`🌍 Environment: ${process.env.NODE_ENV}`);
  console.log(`🔒 Rate Limiting: Enabled`);
  console.log(`⏰ Started at: ${new Date().toISOString()}`);
  console.log('🚀 ================================');
  console.log(`💡 Test the server: curl http://localhost:${PORT}/health`);
  console.log('🚀 ================================');
});

module.exports = app;