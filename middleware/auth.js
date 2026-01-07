const jwt = require('jsonwebtoken');

const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'] || req.headers['Authorization'];
  
  const token = authHeader && authHeader.split(' ')[1];
  
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
      
      if (expiry < now) {
        return res.status(401).json({ 
          error: 'Token expired',
          message: 'Your session has expired. Please login again.'
        });
      }
    }
    
    req.user = decoded;
    next();
    
  } catch (err) {
    return res.status(403).json({ error: 'Invalid token' });
  }
};

module.exports = { authenticateToken };