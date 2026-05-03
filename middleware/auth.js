const jwt = require('jsonwebtoken');

// Clock skew tolerance: 60 seconds buffer for system clock differences
const CLOCK_SKEW_TOLERANCE = 60;

// ⚠️ DEV MODE: Set to true untuk bypass authentication
const BYPASS_AUTH = process.env.BYPASS_AUTH === 'true' || process.env.NODE_ENV === 'development';

const authenticateToken = (req, res, next) => {
  // 🔓 BYPASS MODE: Skip authentication untuk development
  if (BYPASS_AUTH) {
    console.log('🔓 [AUTH BYPASS] Authentication disabled - allowing request');
    console.log('🔓 [AUTH BYPASS] Request URL:', req.url);

    // Set mock user untuk prevent error di code yang membutuhkan req.user
    req.user = {
      id: 0,
      username: 'dev_user',
      email: 'dev@example.com',
      role: 'admin'
    };
    return next();
  }

  const authHeader = req.headers['authorization'] || req.headers['Authorization'];

  const token = authHeader && authHeader.split(' ')[1];

  // console.log('🔐 [Backend Auth] Token received:', token ? token.substring(0, 20) + '...' : 'NO TOKEN');
  // console.log('🔐 [Backend Auth] Auth Header:', authHeader);
  // console.log('🔐 [Backend Auth] Request URL:', req.url);

  if (!token) {
    return res.status(401).json({
      error: 'Access token required',
      message: 'Please login to continue'
    });
  }

  try {
    const decoded = jwt.decode(token);

    if (!decoded) {
      return res.status(403).json({ error: 'Invalid token format' });
    }

    if (decoded.exp) {
      const now = Date.now() / 1000;
      const expiry = decoded.exp;

      // Add clock skew tolerance to prevent false expiration due to system clock differences
      if (expiry < (now - CLOCK_SKEW_TOLERANCE)) {
        console.log(`[Auth] Token expired. Now: ${now}, Expiry: ${expiry}, Diff: ${now - expiry}s`);
        return res.status(401).json({
          error: 'Token expired',
          message: 'Your session has expired. Please login again.'
        });
      }
    }

    req.user = decoded;
    next();

  } catch (err) {
    console.error('[Auth] Token validation error:', err.message);
    return res.status(403).json({ error: 'Invalid token' });
  }
};

module.exports = { authenticateToken };