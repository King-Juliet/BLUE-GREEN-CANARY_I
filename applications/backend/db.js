const AWS = require('aws-sdk');
const { Pool } = require('pg');

const region = process.env.AWS_REGION || 'us-east-1';
const defaultSsmName = process.env.DB_CREDENTIALS_SSM_NAME || '/bluegreen-canary/db/credentials';

AWS.config.update({ region });

function parseDbConfig(rawValue) {
  try {
    const parsed = JSON.parse(rawValue);
    if (parsed.host && parsed.username && parsed.password && parsed.database) {
      return {
        host: parsed.host,
        port: Number(parsed.port || 5432),
        user: parsed.username,
        password: parsed.password,
        database: parsed.database,
        ssl: parsed.ssl === true || parsed.ssl === 'true'
      };
    }
  } catch (error) {
    // Fall through to key=value parser for simple SSM values.
  }

  const fields = {};
  rawValue.split(/\n|\r\n/).forEach((line) => {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) return;
    const idx = trimmed.indexOf('=');
    if (idx >= 0) {
      fields[trimmed.slice(0, idx)] = trimmed.slice(idx + 1);
    }
  });

  if (fields.host && fields.username && fields.password && fields.database) {
    return {
      host: fields.host,
      port: Number(fields.port || 5432),
      user: fields.username,
      password: fields.password,
      database: fields.database,
      ssl: String(fields.ssl || 'false') === 'true'
    };
  }

  return null;
}

async function loadDbConfig(ssmName = defaultSsmName) {
  const ssm = new AWS.SSM();
  const parameter = await ssm.getParameter({
    Name: ssmName,
    WithDecryption: true
  }).promise();

  const parsedConfig = parseDbConfig(parameter.Parameter.Value);
  if (parsedConfig) {
    return parsedConfig;
  }

  return {
    host: process.env.DB_HOST,
    port: Number(process.env.DB_PORT || 5432),
    user: process.env.DB_USER || 'appuser',
    password: parameter.Parameter.Value,
    database: process.env.DB_NAME || 'appdb',
    ssl: process.env.DB_SSL === 'true'
  };
}

async function makePool() {
  if (process.env.DATABASE_URL) {
    return new Pool({ connectionString: process.env.DATABASE_URL });
  }

  try {
    const ssmName = process.env.DB_CREDENTIALS_SSM_NAME || defaultSsmName;
    const dbConfig = await loadDbConfig(ssmName);
    if (dbConfig) {
      return new Pool(dbConfig);
    }
  } catch (error) {
    // If SSM cannot be reached, fall back to direct environment-based values for local development only.
  }

  const fallbackConfig = {
    host: process.env.DB_HOST || 'localhost',
    port: Number(process.env.DB_PORT || 5432),
    user: process.env.DB_USER || 'appuser',
    password: process.env.DB_PASSWORD || '',
    database: process.env.DB_NAME || 'appdb',
    ssl: process.env.DB_SSL === 'true'
  };

  if (!fallbackConfig.password) {
    throw new Error('Database credentials could not be loaded from AWS SSM Parameter Store or local environment variables.');
  }

  return new Pool(fallbackConfig);
}

module.exports = { makePool, parseDbConfig, loadDbConfig };
