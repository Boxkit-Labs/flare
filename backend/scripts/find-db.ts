import pg from 'pg';

const combinations = [
    'postgresql://postgres:postgres@localhost:5432/postgres',
    'postgresql://postgres@localhost:5432/postgres',
    'postgresql://postgres:postgres@localhost:5432/flare',
    'postgresql://postgres@localhost:5432/flare',
];

async function verify() {
    for (const url of combinations) {
        console.log(`Trying ${url}...`);
        const pool = new pg.Pool({ connectionString: url, connectionTimeoutMillis: 2000 });
        try {
            const res = await pool.query('SELECT 1');
            console.log('✅ Success:', url);
            process.exit(0);
        } catch (e: any) {
            console.log('❌ Failed:', e.message);
        } finally {
            await pool.end();
        }
    }
    process.exit(1);
}

verify();
