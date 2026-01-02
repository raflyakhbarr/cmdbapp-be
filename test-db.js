const pool = require('./db');

(async () => {
  try {
    const res = await pool.query('SELECT NOW()');
    console.log('✅ Connected to Neon:', res.rows[0]);
    process.exit(0);
  } catch (err) {
    console.error('❌ DB Error:', err);
    process.exit(1);
  }
})();
