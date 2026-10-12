-- Orders v1 baseline. Safe to run on databases that were created by hand.
CREATE TABLE IF NOT EXISTS products (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  category VARCHAR(100) NOT NULL,
  price NUMERIC(10,2) NOT NULL,
  description TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS orders (
  id SERIAL PRIMARY KEY,
  customer_name VARCHAR(255) NOT NULL,
  customer_email VARCHAR(255) NOT NULL,
  city VARCHAR(100) NOT NULL,
  product_id INTEGER NOT NULL,
  product_name VARCHAR(255) NOT NULL,
  price NUMERIC(10,2) NOT NULL,
  status VARCHAR(50) NOT NULL DEFAULT 'created',
  schema_version VARCHAR(50) NOT NULL DEFAULT 'orders.v1',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);