const PB_URL = 'http://127.0.0.1:8090';
const ADMIN_EMAIL = 'admin@pos.local';
const ADMIN_PASS = '1234567890'; // Use the password we set in init_schema.js

async function checkCounts() {
    try {
        const authRes = await fetch(`${PB_URL}/api/collections/_superusers/auth-with-password`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ identity: ADMIN_EMAIL, password: ADMIN_PASS })
        });
        const authData = await authRes.json();
        const token = authData.token;

        if (!token) {
            console.error('Auth failed', authData);
            return;
        }

        const headers = { 'Authorization': token };

        const collections = ['categories', 'menu_items', 'orders', 'users', 'payments'];

        for (const col of collections) {
            const res = await fetch(`${PB_URL}/api/collections/${col}/records?perPage=1&skipTotal=false`, { headers });
            const data = await res.json();
            console.log(`${col}: ${data.totalItems} records`);
        }
    } catch (e) {
        console.error(e);
    }
}

checkCounts();
