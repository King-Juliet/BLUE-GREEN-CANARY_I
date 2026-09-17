const schemaRegistry = {
  products: {
    v1: {
      subject: 'products',
      version: 1,
      fields: ['id', 'name', 'category', 'price'],
      compatibility: 'BACKWARD',
      description: 'Canonical product contract for frontend listing and ordering.'
    }
  },
  orders: {
    v1: {
      subject: 'orders',
      version: 1,
      fields: ['id', 'customer_name', 'customer_email', 'city', 'product_id', 'product_name', 'price', 'status', 'schema_version'],
      compatibility: 'BACKWARD',
      description: 'Canonical order contract for database and API exchange.'
    }
  },
  compatibilityPolicy: {
    strategy: 'write canonical fields, read flexible record shapes, ignore unknown fields',
    policy: 'READ_OLD_WRITE_NEW',
    note: 'Backend must tolerate schema drift with missing or extra columns.'
  }
};

module.exports = schemaRegistry;
