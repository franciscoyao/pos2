const PB_URL = 'http://127.0.0.1:8090';
const ADMIN_EMAIL = 'admin@pos.local';
const ADMIN_PASS = '1234567890';

async function main() {
    // 1. Authenticate as superuser
    const authRes = await fetch(`${PB_URL}/api/collections/_superusers/auth-with-password`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ identity: ADMIN_EMAIL, password: ADMIN_PASS })
    });
    const authData = await authRes.json();
    const token = authData.token;

    if (!token) {
        console.error('Auth failed:', authData);
        return;
    }
    console.log('Authenticated.');

    const headers = {
        'Content-Type': 'application/json',
        'Authorization': token
    };

    // 2. Set API rules on all custom collections
    // Empty string "" means "any authenticated user can perform this action"
    const rule = '';  // Allow all authenticated users

    const collections = ['restaurant_tables', 'categories', 'menu_items', 'orders', 'order_items'];

    for (const name of collections) {
        try {
            const res = await fetch(`${PB_URL}/api/collections/${name}`, {
                method: 'PATCH',
                headers,
                body: JSON.stringify({
                    listRule: rule,
                    viewRule: rule,
                    createRule: rule,
                    updateRule: rule,
                    deleteRule: rule
                })
            });

            if (res.ok) {
                console.log(`✓ Set API rules for: ${name}`);
            } else {
                const err = await res.text();
                console.error(`✗ Failed to set rules for ${name}:`, err);
            }
        } catch (e) {
            console.error(`✗ Error updating ${name}:`, e);
        }
    }

    console.log('Done! All collections now accessible to authenticated users.');
}

main();
