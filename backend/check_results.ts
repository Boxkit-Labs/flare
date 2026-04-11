import pool from './src/db/database.js';
async function run() {
  try {
    const res = await pool.query('SELECT * FROM checks ORDER BY checked_at DESC LIMIT 5');
    console.log(JSON.stringify(res.rows, null, 2));
  } catch (err) {
    console.error(err);
  } finally {
    process.exit(0);
  }
}
run();
