import pool from './src/db/database.js';
async function run() {
  try {
    const res = await pool.query("SELECT * FROM checks WHERE checked_at > NOW() - INTERVAL '10 minutes' ORDER BY checked_at DESC");
    console.log('Recent checks (last 10m):', res.rows.length);
    console.log(JSON.stringify(res.rows, null, 2));
    
    const chanRes = await pool.query("SELECT * FROM mpp_channels ORDER BY opened_at DESC LIMIT 5");
    console.log('Recent channels:', JSON.stringify(chanRes.rows, null, 2));
  } catch (err) {
    console.error(err);
  } finally {
    process.exit(0);
  }
}
run();
