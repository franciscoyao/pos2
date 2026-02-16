const PB_URL = 'http://127.0.0.1:8090';
const ADMIN_EMAIL = 'admin@pos.local';
const ADMIN_PASS = '1234567890';

async function main() {
    // 1. Authenticate
    let token;
    try {
        const authRes = await fetch(`${PB_URL}/api/collections/_superusers/auth-with-password`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ identity: ADMIN_EMAIL, password: ADMIN_PASS })
        });
        const authData = await authRes.json();
        token = authData.token;
        if (!token) throw new Error("No token returned");
    } catch (e) {
        console.error('Failed to authenticate as admin. Ensure PB is running and admin exists.', e);
        return;
    }
    console.log('Authenticated as admin.');

    const headers = {
        'Content-Type': 'application/json',
        'Authorization': token
    };

    // 2. Update Users Collection (Schema & Options)
    try {
        const collectionsRes = await fetch(`${PB_URL}/api/collections`, { headers });
        const collectionsData = await collectionsRes.json();
        const usersCol = collectionsData.items.find(c => c.name === 'users');

        if (usersCol) {
            console.log('Found users collection.');
            const newFields = [
                { name: 'fullName', type: 'text' },
                { name: 'pin', type: 'text' },
                { name: 'role', type: 'select', options: { maxSelect: 1, values: ['admin', 'waiter', 'kitchen', 'bar'] } },
                { name: 'status', type: 'select', options: { maxSelect: 1, values: ['active', 'inactive'] } }
            ];

            // Filter out existing fields to avoid duplication/errors
            const currentSchema = usersCol.schema || [];
            const currentFieldNames = currentSchema.map(f => f.name);
            const fieldsToAdd = newFields.filter(f => !currentFieldNames.includes(f.name));

            const updatedSchema = [...currentSchema, ...fieldsToAdd];

            // Update Options for 4-digit PIN password
            const updatedOptions = {
                ...usersCol.options,
                minPasswordLength: 4,
                allowUsernameAuth: true,
                requireEmail: false
            };

            await fetch(`${PB_URL}/api/collections/${usersCol.id}`, {
                method: 'PATCH',
                headers,
                body: JSON.stringify({
                    schema: updatedSchema,
                    options: updatedOptions
                })
            });
            console.log('Updated users collection schema and options.');
        }
    } catch (e) {
        console.error('Error updating users collection:', e);
    }

    // 3. Seed Users
    // PB requires min password length (default 8, likely min 5).
    // Our app uses 4-digit PIN. We will pad it with "0000" for the actual password.
    try {
        await seedUser('admin', '11110000', {
            password: '11110000',
            passwordConfirm: '11110000',
            fullName: 'System Admin',
            role: 'admin',
            pin: '1111',
            status: 'active'
        }, headers);

        await seedUser('waiter', '22220000', {
            password: '22220000',
            passwordConfirm: '22220000',
            fullName: 'John Waiter',
            role: 'waiter',
            pin: '2222',
            status: 'active'
        }, headers);

    } catch (e) {
        console.error('Error seeding users:', e);
    }

    // 4. Create Collections (if not exist)
    // Refresh collections list
    collections = (await (await fetch(`${PB_URL}/api/collections`, { headers })).json());

    // ... (rest of the collection creation logic, reusing existing variable 'collections')
    const collectionsToCreate = [
        {
            name: 'restaurant_tables',
            type: 'base',
            listRule: '', viewRule: '', createRule: '@request.auth.id != ""', updateRule: '@request.auth.id != ""', deleteRule: '@request.auth.id != ""',
            schema: [
                { name: 'name', type: 'text', required: true },
                { name: 'status', type: 'select', options: { maxSelect: 1, values: ['available', 'occupied', 'payment', 'cleaning'] } },
                { name: 'x', type: 'number' },
                { name: 'y', type: 'number' }
            ]
        },
        {
            name: 'categories',
            type: 'base',
            listRule: '', viewRule: '', createRule: '@request.auth.id != ""', updateRule: '@request.auth.id != ""', deleteRule: '@request.auth.id != ""',
            schema: [
                { name: 'name', type: 'text', required: true },
                { name: 'menuType', type: 'select', options: { maxSelect: 1, values: ['dine-in', 'takeaway'] } },
                { name: 'sortOrder', type: 'number' },
                { name: 'station', type: 'text' },
                { name: 'status', type: 'text' }
            ]
        },
        {
            name: 'menu_items',
            type: 'base',
            listRule: '', viewRule: '', createRule: '@request.auth.id != ""', updateRule: '@request.auth.id != ""', deleteRule: '@request.auth.id != ""',
            schema: [
                { name: 'code', type: 'text' },
                { name: 'name', type: 'text', required: true },
                { name: 'price', type: 'number', required: true },
                { name: 'station', type: 'text' },
                { name: 'type', type: 'text' },
                { name: 'status', type: 'text' },
                { name: 'allowPriceEdit', type: 'bool' },
                { name: 'category', type: 'relation', collectionId: 'categories', cascadeDelete: false, maxSelect: 1 }
            ]
        },
        {
            name: 'orders',
            type: 'base',
            listRule: '@request.auth.id != ""', viewRule: '@request.auth.id != ""', createRule: '@request.auth.id != ""', updateRule: '@request.auth.id != ""', deleteRule: '@request.auth.id != ""',
            schema: [
                { name: 'orderNumber', type: 'text' },
                { name: 'tableNumber', type: 'text' },
                { name: 'type', type: 'text' },
                { name: 'status', type: 'text' },
                { name: 'totalAmount', type: 'number' },
                { name: 'taxAmount', type: 'number' },
                { name: 'serviceAmount', type: 'number' },
                { name: 'paymentMethod', type: 'text' },
                { name: 'tipAmount', type: 'number' },
                { name: 'taxNumber', type: 'text' },
                { name: 'completedAt', type: 'date' }
            ]
        },
        {
            name: 'order_items',
            type: 'base',
            listRule: '@request.auth.id != ""', viewRule: '@request.auth.id != ""', createRule: '@request.auth.id != ""', updateRule: '@request.auth.id != ""', deleteRule: '@request.auth.id != ""',
            schema: [
                { name: 'order', type: 'relation', collectionId: 'orders', cascadeDelete: true, maxSelect: 1 },
                { name: 'menuItem', type: 'relation', collectionId: 'menu_items', cascadeDelete: false, maxSelect: 1 },
                { name: 'quantity', type: 'number' },
                { name: 'priceAtTime', type: 'number' },
                { name: 'status', type: 'text' }
            ]
        },
        {
            name: 'payments',
            type: 'base',
            listRule: '@request.auth.id != ""', viewRule: '@request.auth.id != ""', createRule: '@request.auth.id != ""', updateRule: '@request.auth.id != ""', deleteRule: '@request.auth.id != ""',
            schema: [
                { name: 'order', type: 'relation', collectionId: 'orders', cascadeDelete: false, maxSelect: 1 },
                { name: 'amount', type: 'number', required: true },
                { name: 'method', type: 'text', required: true },
                { name: 'status', type: 'text' },
                { name: 'itemsJSON', type: 'json' }
            ]
        }
    ];

    for (const col of collectionsToCreate) {
        // For Relation fields, resolve ID
        for (const field of col.schema) {
            if (field.type === 'relation' && field.collectionId) {
                const targetCol = collections.items.find(c => c.name === field.collectionId) || (await getCollectionByName(field.collectionId, headers));
                if (targetCol) {
                    field.collectionId = targetCol.id;
                }
            }
        }

        // Check if exists
        const existing = collections.items.find(c => c.name === col.name);
        if (existing) {
            console.log(`Collection ${col.name} already exists. Updating rules...`);
            // Update rules
            try {
                await fetch(`${PB_URL}/api/collections/${existing.id}`, {
                    method: 'PATCH',
                    headers,
                    body: JSON.stringify({
                        listRule: col.listRule,
                        viewRule: col.viewRule,
                        createRule: col.createRule,
                        updateRule: col.updateRule,
                        deleteRule: col.deleteRule
                    })
                });
            } catch (e) { console.error(`Failed to update rules for ${col.name}`, e); }
            continue;
        }

        const res = await fetch(`${PB_URL}/api/collections`, {
            method: 'POST',
            headers,
            body: JSON.stringify(col)
        });

        if (res.ok) {
            console.log(`Created collection: ${col.name}`);
            collections = (await (await fetch(`${PB_URL}/api/collections`, { headers })).json());
        } else {
            console.error(`Failed to create ${col.name}:`, await res.text());
        }
    }
}

async function seedUser(username, password, data, headers) {
    // Check if user exists
    const res = await fetch(`${PB_URL}/api/collections/users/records?filter=(username='${username}')`, { headers });
    const json = await res.json();
    if (json.items && json.items.length > 0) {
        console.log(`User ${username} already exists. Updating...`);
        const id = json.items[0].id;
        // Update
        await fetch(`${PB_URL}/api/collections/users/records/${id}`, {
            method: 'PATCH',
            headers,
            body: JSON.stringify(data)
        });
    } else {
        console.log(`Creating user ${username}...`);
        const createRes = await fetch(`${PB_URL}/api/collections/users/records`, {
            method: 'POST',
            headers,
            body: JSON.stringify({
                username,
                email: `${username}@pos.local`,
                emailVisibility: true,
                ...data
            })
        });
        if (!createRes.ok) {
            console.error(`Failed to create user ${username}:`, await createRes.text());
        }
    }
}

async function getCollectionByName(name, headers) {
    const res = await fetch(`${PB_URL}/api/collections?filter=(name='${name}')`, { headers });
    const data = await res.json();
    return data.items?.[0];
}

let collections = { items: [] };

main();
