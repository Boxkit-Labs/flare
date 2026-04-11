import pg from 'pg';

const combinations = [
    'postgresql://postgres:4rNwDoiJQhyily1UPSFgFVx2Lat3x1ev@localhost:5432/postgres',
    'postgresql://flare:4rNwDoiJQhyily1UPSFgFVx2Lat3x1ev@localhost:5432/flare',
    'postgresql://postgres:postgres@localhost:5432/postgres',
    'postgresql://postgres:password@localhost:5432/postgres',
    'postgresql://postgres:admin@localhost:5432/postgres',
    'postgresql://postgres:root@localhost:5432/postgres',
    'postgresql://postgres:flare@localhost:5432/postgres',
    'postgresql://postgres:Postgres123@localhost:5432/postgres',
    'postgresql://postgres:postgres123@localhost:5432/postgres',
    'postgresql://postgres@localhost:5432/postgres',
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
