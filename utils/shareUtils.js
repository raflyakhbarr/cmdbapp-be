const crypto = require('crypto');

/**
 * Generate a random share token
 * Format: 8 character alphanumeric string
 */
function generateShareToken() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Removed confusing characters (0/O, 1/I)
  const bytes = crypto.randomBytes(8); // 8 bytes for 8 characters
  let token = '';

  for (let i = 0; i < 8; i++) {
    const byte = bytes[i];
    const index = byte % chars.length;
    token += chars[index];
  }

  return token;
}

/**
 * Calculate expiration date based on duration
 */
function calculateExpirationDate(duration) {
  const now = new Date();

  switch (duration) {
    case '1h':
      return new Date(now.getTime() + 60 * 60 * 1000);
    case '1d':
      return new Date(now.getTime() + 24 * 60 * 60 * 1000);
    case '7d':
      return new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);
    case '30d':
      return new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000);
    case 'never':
      return null;
    default:
      return null;
  }
}

module.exports = {
  generateShareToken,
  calculateExpirationDate
};
