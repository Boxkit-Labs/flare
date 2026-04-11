import pool from '../db/database.js';
import 'dotenv/config';

async function wipe() {
    console.log('--- Database Wipe Sequence ---');
    try {
        console.log('Deleting findings...');
        await pool.query('DELETE FROM findings');
        
        console.log('Deleting checks...');
        await pool.query('DELETE FROM checks');
        
        console.log('Deleting watchers...');
        await pool.query('DELETE FROM watchers');
        
        console.log('Deleting mpp_channels...');
        await pool.query('DELETE FROM mpp_channels');
        
        console.log('Deleting transactions...');
        await pool.query('DELETE FROM transactions');
        
        console.log('Wipe complete. Starting clean.');
    } catch (err: any) {
        console.error('Wipe failed:', err.message);
    }
    process.exit(0);
}

wipe();
