const PB_URL = 'http://127.0.0.1:8090';
const ADMIN_EMAIL = 'admin@pos.local';
const ADMIN_PASS = '1234567890';

async function seedMenu() {
    // 1. Auth
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
        console.error('Auth failed', e);
        return;
    }
    const headers = { 'Content-Type': 'application/json', 'Authorization': token };

    // 2. Create Categories
    const categories = [
        { name: 'Drinks', menuType: 'dine-in', sortOrder: 1, station: 'bar', status: 'active' },
        { name: 'Mains', menuType: 'dine-in', sortOrder: 2, station: 'kitchen', status: 'active' },
        { name: 'Dessert', menuType: 'dine-in', sortOrder: 3, station: 'kitchen', status: 'active' }
    ];

    const categoryMap = {}; // name -> id

    for (const cat of categories) {
        try {
            // Check existing
            const filter = encodeURIComponent(`name='${cat.name}'`);
            const existingRes = await fetch(`${PB_URL}/api/collections/categories/records?filter=${filter}`, { headers });
            const existing = await existingRes.json();

            if (existing.items && existing.items.length > 0) {
                console.log(`Category ${cat.name} exists.`);
                categoryMap[cat.name] = existing.items[0].id;
            } else {
                const res = await fetch(`${PB_URL}/api/collections/categories/records`, {
                    method: 'POST',
                    headers,
                    body: JSON.stringify(cat)
                });
                if (!res.ok) {
                    console.error(`Failed to create category ${cat.name}`, await res.text());
                    continue;
                }
                const data = await res.json();
                console.log(`Created category ${cat.name}`);
                categoryMap[cat.name] = data.id;
            }
        } catch (e) {
            console.error(`Error creating category ${cat.name}`, e);
        }
    }

    // 3. Create Menu Items
    const items = [
        { name: 'Cola', price: 2.5, category: 'Drinks', station: 'bar', type: 'dine-in' },
        { name: 'Water', price: 1.0, category: 'Drinks', station: 'bar', type: 'dine-in' },
        { name: 'Burger', price: 12.0, category: 'Mains', station: 'kitchen', type: 'dine-in' },
        { name: 'Fries', price: 4.0, category: 'Mains', station: 'kitchen', type: 'dine-in' },
        { name: 'Steak', price: 25.0, category: 'Mains', station: 'kitchen', type: 'dine-in' },
        { name: 'Ice Cream', price: 5.0, category: 'Dessert', station: 'kitchen', type: 'dine-in' }
    ];

    for (const item of items) {
        try {
            // Check existing
            const filter = encodeURIComponent(`name='${item.name}'`);
            const existingRes = await fetch(`${PB_URL}/api/collections/menu_items/records?filter=${filter}`, { headers });
            const existing = await existingRes.json();

            if (existing.items && existing.items.length > 0) {
                console.log(`Item ${item.name} exists.`);
            } else {
                const catId = categoryMap[item.category];
                if (!catId) {
                    console.error(`Category ID not found for ${item.category}`);
                    continue;
                }

                const res = await fetch(`${PB_URL}/api/collections/menu_items/records`, {
                    method: 'POST',
                    headers,
                    body: JSON.stringify({
                        ...item,
                        category: catId,
                        status: 'active',
                        allowPriceEdit: false
                    })
                });
                if (res.ok) {
                    console.log(`Created item ${item.name}`);
                } else {
                    console.error(`Failed to create item ${item.name}`, await res.text());
                }
            }
        } catch (e) {
            console.error(`Error creating item ${item.name}`, e);
        }
    }
}

seedMenu();
