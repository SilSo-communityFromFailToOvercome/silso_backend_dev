const {onRequest} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const admin = require('firebase-admin');
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const axios = require('axios');
const { GoogleGenerativeAI } = require('@google/generative-ai');

// Initialize Firebase Admin SDK (automatically uses project credentials in Functions)
if (!admin.apps.length) {
  admin.initializeApp();
  logger.info('🔥 Firebase Admin SDK initialized successfully');
}

// Initialize Gemini AI
const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
const geminiModel = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });
logger.info('🤖 Gemini AI initialized successfully');

const app = express();

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
  origin: true, // Allow all origins in Functions (Firebase handles CORS)
  credentials: true,
  methods: ['GET', 'POST', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));

// Configure trust proxy for Firebase Functions
app.set('trust proxy', true);

app.use(generalLimiter);
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Logging middleware
app.use((req, res, next) => {
  logger.info(`${new Date().toISOString()} - ${req.method} ${req.path} - ${req.ip}`);
  next();
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ 
    status: 'OK', 
    timestamp: new Date().toISOString(),
    service: 'Silso Auth Backend (Firebase Functions)',
    version: '1.0.0',
    environment: 'production'
  });
});

// API info endpoint
app.get('/api/info', (req, res) => {
  res.json({
    service: 'Silso Authentication Backend (Firebase Functions)',
    version: '1.0.0',
    endpoints: [
      'GET /health - Health check',
      'GET /api/info - API information',
      'POST /auth/kakao/custom-token - Kakao authentication',
      'POST /auth/kakao/exchange-code - Exchange authorization code for access token',
      'POST /court/generate-conclusion - Generate AI court session conclusion'
    ],
    environment: 'production'
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

    logger.info('🟡 Starting Kakao authentication process...');

    // Step 1: Verify Kakao access token and get user info
    const kakaoUserInfo = await getKakaoUserInfo(kakao_access_token);
    logger.info('✅ Kakao user info retrieved successfully');
    
    // Step 2: Create Firebase custom token
    const customToken = await createFirebaseCustomToken(kakaoUserInfo);
    logger.info('✅ Firebase custom token created successfully');
    
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

    logger.info(`✅ Kakao authentication completed successfully in ${processingTime}ms`);

  } catch (error) {
    const processingTime = Date.now() - startTime;
    logger.error('❌ Kakao auth error:', error.message);
    
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

    logger.info('🟡 Exchanging Kakao authorization code for access token...');

    // Exchange authorization code for access token
    const accessToken = await exchangeKakaoCodeForToken(authorization_code, redirect_uri);
    logger.info('✅ Kakao access token obtained successfully');
    
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
    logger.error('❌ Kakao code exchange error:', error.message);
    
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
    logger.info('🟡 Calling Kakao token endpoint...');
    
    // Get Kakao credentials from Firebase Functions config
    const kakaoRestApiKey = process.env.KAKAO_REST_API_KEY;
    const kakaoClientSecret = process.env.KAKAO_CLIENT_SECRET;
    
    const response = await axios.post('https://kauth.kakao.com/oauth/token', {
      grant_type: 'authorization_code',
      client_id: kakaoRestApiKey,
      client_secret: kakaoClientSecret,
      code: authorizationCode,
      redirect_uri: redirectUri
    }, {
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded'
      },
      timeout: 10000 // 10 second timeout
    });
    
    logger.info('✅ Kakao token response received');
    
    if (response.data.access_token) {
      return response.data.access_token;
    } else {
      throw new Error('No access token in Kakao response');
    }
  } catch (error) {
    logger.error('❌ Kakao token exchange error:', error.response?.data || error.message);
    
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
      logger.info('🟡 Using DEMO Kakao user data for testing...');
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
    
    logger.info('🟡 Requesting user info from Kakao API...');
    
    const response = await axios.get('https://kapi.kakao.com/v2/user/me', {
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type': 'application/x-www-form-urlencoded;charset=utf-8'
      },
      timeout: 10000 // 10 second timeout
    });
    
    logger.info('✅ Kakao API response received');
    return response.data;
  } catch (error) {
    logger.error('❌ Kakao API error:', error.response?.data || error.message);
    
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
    logger.info('🟡 Creating Firebase custom token...');
    
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
    
    logger.info('✅ Firebase custom token created');
    return customToken;
  } catch (error) {
    logger.error('❌ Firebase custom token creation error:', error);
    const firebaseError = new Error(`Failed to create Firebase custom token: ${error.message}`);
    firebaseError.code = 'FIREBASE_ERROR';
    throw firebaseError;
  }
}

// Court AI Conclusion Generation Endpoint
app.post('/court/generate-conclusion', async (req, res) => {
  const startTime = Date.now();
  
  try {
    const { court_session_data } = req.body;

    // Validate request
    if (!court_session_data) {
      return res.status(400).json({ 
        error: 'Bad Request',
        message: 'court_session_data is required',
        code: 'MISSING_COURT_DATA'
      });
    }

    // Validate required court session fields
    const { case_title, case_description, chat_messages, votes, session_duration } = court_session_data;
    
    if (!case_title || !case_description || !chat_messages || !votes) {
      return res.status(400).json({ 
        error: 'Bad Request',
        message: 'Missing required court session data: case_title, case_description, chat_messages, votes',
        code: 'INCOMPLETE_COURT_DATA'
      });
    }

    logger.info('🏛️ Starting AI court conclusion generation...');

    // Generate AI conclusion using Gemini
    const conclusion = await generateCourtConclusion(court_session_data);
    logger.info('✅ AI court conclusion generated successfully');
    
    // Return the generated conclusion
    const processingTime = Date.now() - startTime;
    res.json({
      success: true,
      conclusion: conclusion,
      metadata: {
        case_title: case_title,
        total_messages: chat_messages.length,
        total_votes: votes.length,
        session_duration: session_duration,
        ai_model: 'gemini-1.5-flash',
        processing_time_ms: processingTime,
        timestamp: new Date().toISOString()
      }
    });

    logger.info(`✅ Court conclusion completed successfully in ${processingTime}ms`);

  } catch (error) {
    const processingTime = Date.now() - startTime;
    logger.error('❌ Court conclusion generation error:', error.message);
    
    // Handle specific error types
    if (error.message.includes('API_KEY')) {
      return res.status(401).json({ 
        error: 'Unauthorized',
        message: 'Invalid or missing Gemini API key',
        code: 'INVALID_GEMINI_API_KEY',
        processing_time_ms: processingTime
      });
    }
    
    if (error.message.includes('QUOTA_EXCEEDED')) {
      return res.status(429).json({ 
        error: 'Too Many Requests',
        message: 'Gemini API quota exceeded',
        code: 'GEMINI_QUOTA_EXCEEDED',
        processing_time_ms: processingTime
      });
    }

    if (error.message.includes('SAFETY')) {
      return res.status(400).json({ 
        error: 'Bad Request',
        message: 'Content flagged by AI safety filters',
        code: 'CONTENT_SAFETY_VIOLATION',
        processing_time_ms: processingTime
      });
    }
    
    // Generic error response
    res.status(500).json({ 
      error: 'Internal Server Error',
      message: 'AI conclusion generation failed. Please try again.',
      code: 'AI_GENERATION_FAILED',
      processing_time_ms: processingTime
    });
  }
});

// Function to generate court conclusion using Gemini AI
async function generateCourtConclusion(courtSessionData) {
  try {
    const { case_title, case_description, chat_messages, votes, session_duration } = courtSessionData;

    logger.info('🤖 Calling Gemini AI for court conclusion...');
    
    // Prepare chat messages for AI
    const chatHistory = chat_messages
      .slice(-50) // Limit to last 50 messages to stay within token limits
      .map(msg => `${msg.sender_name}: ${msg.message}`)
      .join('\n');
    
    // Prepare votes summary
    const votesSummary = votes.map(vote => 
      `Vote: ${vote.verdict} - Reasoning: ${vote.reasoning || 'No reasoning provided'}`
    ).join('\n');
    
    // Calculate vote statistics
    const guiltyVotes = votes.filter(v => v.verdict === 'guilty').length;
    const notGuiltyVotes = votes.filter(v => v.verdict === 'not_guilty').length;
    const totalVotes = votes.length;
    
    // Create AI prompt
    const prompt = `You are a professional legal AI assistant helping to summarize a court session conclusion.

CASE INFORMATION:
Title: ${case_title}
Description: ${case_description}
Session Duration: ${session_duration || 'Not specified'}

COURT SESSION DISCUSSION:
${chatHistory}

JURY VOTES (${totalVotes} total):
- Guilty: ${guiltyVotes} votes
- Not Guilty: ${notGuiltyVotes} votes

INDIVIDUAL VOTE REASONING:
${votesSummary}

TASK:
Generate a fair, balanced, and professional court session conclusion that:
1. Summarizes the key arguments presented
2. Explains the final verdict based on majority vote
3. Highlights the main reasoning from jurors
4. Maintains judicial neutrality and professionalism
5. Is concise but comprehensive (200-400 words)

Please format the response as a structured conclusion with clear sections.`;

    // Call Gemini AI
    const result = await geminiModel.generateContent(prompt);
    const response = await result.response;
    const conclusion = response.text();
    
    logger.info('✅ Gemini AI response received successfully');
    
    // Add verdict determination
    const finalVerdict = guiltyVotes > notGuiltyVotes ? 'GUILTY' : 'NOT GUILTY';
    
    return {
      verdict: finalVerdict,
      vote_breakdown: {
        guilty: guiltyVotes,
        not_guilty: notGuiltyVotes,
        total: totalVotes
      },
      ai_generated_summary: conclusion,
      confidence_score: Math.round((Math.max(guiltyVotes, notGuiltyVotes) / totalVotes) * 100),
      generated_at: new Date().toISOString()
    };
    
  } catch (error) {
    logger.error('❌ Gemini AI error:', error.message);
    
    if (error.message.includes('API_KEY_INVALID')) {
      throw new Error('Invalid Gemini API_KEY configuration');
    }
    
    if (error.message.includes('QUOTA_EXCEEDED')) {
      throw new Error('Gemini API QUOTA_EXCEEDED');
    }
    
    if (error.message.includes('SAFETY')) {
      throw new Error('Content flagged by Gemini SAFETY filters');
    }
    
    throw new Error(`Gemini AI generation failed: ${error.message}`);
  }
}

// Error handling middleware
app.use((error, req, res, next) => {
  logger.error('❌ Unhandled error:', error);
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

// Export the Express app as a Firebase Function
exports.api = onRequest({
  cors: true,
  region: 'us-central1',
  memory: '256MiB',
  timeoutSeconds: 60,
  maxInstances: 10,
  invoker: 'public'  // Allow unauthenticated access
}, app);