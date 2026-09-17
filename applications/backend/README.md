# Backend application

This backend is a simple Express + PostgreSQL ecommerce API scaffold.

## Environment

Use the example environment file:

```bash
cp .env.example .env
```

The preferred database credential route is AWS Systems Manager Parameter Store. Set:

```bash
DB_CREDENTIALS_SSM_NAME=/bluegreen-canary/db/credentials
```

The Parameter Store JSON value may look like:

```json
{
  "host": "appdb.example.us-east-1.rds.amazonaws.com",
  "port": 5432,
  "username": "appuser",
  "password": "StrongPassword!",
  "database": "appdb",
  "ssl": true
}
```

The code falls back to `DATABASE_URL` or direct environment variables if SSM is not used.
