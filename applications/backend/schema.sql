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

CREATE TABLE IF NOT EXISTS schema_registry (
  id SERIAL PRIMARY KEY,
  subject VARCHAR(100) NOT NULL,
  version INTEGER NOT NULL,
  schema JSONB NOT NULL,
  compatibility VARCHAR(50) NOT NULL DEFAULT 'BACKWARD',
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(subject, version)
);

INSERT INTO schema_registry(subject, version, schema, compatibility, is_active)
VALUES
  ('products', 1, '{"type":"object","required":["id","name","category","price"],"properties":{"id":{"type":"integer"},"name":{"type":"string"},"category":{"type":"string"},"price":{"type":"number"}}}', 'BACKWARD', true),
  ('orders', 1, '{"type":"object","required":["id","customer_name","customer_email","city","product_id","product_name","price","status","schema_version"],"properties":{"id":{"type":"integer"},"customer_name":{"type":"string"},"customer_email":{"type":"string"},"city":{"type":"string"},"product_id":{"type":"integer"},"product_name":{"type":"string"},"price":{"type":"number"},"status":{"type":"string"},"schema_version":{"type":"string"}}}', 'BACKWARD', true)
ON CONFLICT DO NOTHING;
