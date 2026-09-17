const express = require('express');
const cors = require('cors');
const { makePool } = require('./db');
const schemaRegistry = require('./schema-registry');

const app = express();
const port = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

let pool;

async function setupDb() {
  pool = await makePool();
}

setupDb().catch((error) => {
  console.error('Database initialization failed:', error.message);
});

const products = [
  { id: 1, name: 'Green Ceramic Bottle', category: 'Lifestyle', price: 34 },
  { id: 2, name: 'Everyday Candle', category: 'Home', price: 18 },
  { id: 3, name: 'Desk Lamp', category: 'Office', price: 42 },
  { id: 4, name: 'Glow Skin Kit', category: 'Beauty', price: 29 },
  { id: 5, name: 'Daily Cotton Set', category: 'Lifestyle', price: 26 },
  { id: 6, name: 'Minimal Chair', category: 'Home', price: 76 },
  { id: 7, name: 'Focus Journal', category: 'Office', price: 14 },
  { id: 8, name: 'Harvest Basket', category: 'Home', price: 38 }
];

async function healthHandler(req, res) {
  try {
    if (!pool) {
      return res.status(503).json({ status: 'degraded', db: 'not-ready' });
    }

    await pool.query('SELECT 1');
    res.json({ status: 'healthy', mode: process.env.NODE_ENV || 'development', region: process.env.AWS_REGION || 'local' });
  } catch (error) {
    res.status(503).json({ status: 'degraded', db: 'down', mode: process.env.NODE_ENV || 'development' });
  }
}

app.get('/health', healthHandler);
app.get('/api/health', healthHandler);

app.get('/api/products', (req, res) => {
  res.json({ products, schema: 'products.v1' });
});

app.get('/api/schema-registry', (req, res) => {
  res.json({ registry: schemaRegistry });
});

app.post('/api/orders', async (req, res) => {
  const { customerName, customerEmail, city, productId } = req.body;

  if (!customerName || !customerEmail || !city || !productId) {
    return res.status(400).json({ message: 'Missing required fields' });
  }

  const product = products.find((item) => item.id === Number(productId));
  if (!product) {
    return res.status(400).json({ message: 'Unknown product' });
  }

  try {
    const orderResult = await pool.query(
      `
        INSERT INTO orders (customer_name, customer_email, city, product_id, product_name, price, status, schema_version)
        VALUES ($1, $2, $3, $4, $5, $6, 'created', 'orders.v1')
        RETURNING id
      `,
      [customerName, customerEmail, city, product.id, product.name, product.price]
    );

    const createdOrder = {
      id: orderResult.rows[0].id,
      customerName,
      customerEmail,
      city,
      productId: product.id,
      productName: product.name,
      price: product.price,
      status: 'created',
      schemaVersion: 'orders.v1'
    };

    res.status(201).json({ order: createdOrder, compatibility: schemaRegistry.compatibilityPolicy });
  } catch (error) {
    res.status(500).json({ message: 'Order creation failed', error: error.message });
  }
});

app.get('/api/orders/:id', async (req, res) => {
  try {
    const result = await pool.query(`SELECT * FROM orders WHERE id = $1`, [req.params.id]);
    if (result.rows.length === 0) {
      return res.status(404).json({ message: 'Order not found' });
    }

    res.json({ order: result.rows[0], schema: 'orders.v1' });
  } catch (error) {
    res.status(500).json({ message: 'Could not read order', error: error.message });
  }
});

app.listen(port, () => {
  console.log(`Backend running on http://localhost:${port}`);
});
