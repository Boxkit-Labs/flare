import pool from './db/database.js';

async function main() {
    try {
        const res = await pool.query('SELECT user_id FROM users LIMIT 1');
        if (res.rows.length > 0) {
            console.log('USER_ID:' + res.rows[0].user_id);
        } else {
            console.log('NO_USERS_FOUND');
        }
    } catch (err) {
        console.error(err);
    } finally {
        await pool.end();
    }
}

main();
