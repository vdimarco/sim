// Create database tables for Sim registration
const { Client } = require('pg');

async function createTables() {
  const client = new Client({
    connectionString: process.env.DATABASE_URL,
  });

  try {
    await client.connect();
    console.log('Connected to database');

    // Create user table
    console.log('Creating user table...');
    await client.query(`
      CREATE TABLE IF NOT EXISTS "user" (
        "id" text PRIMARY KEY,
        "name" text NOT NULL,
        "email" text NOT NULL UNIQUE,
        "email_verified" boolean NOT NULL DEFAULT false,
        "image" text,
        "created_at" timestamp NOT NULL DEFAULT now(),
        "updated_at" timestamp NOT NULL DEFAULT now(),
        "stripe_customer_id" text
      );
    `);

    // Create session table
    console.log('Creating session table...');
    await client.query(`
      CREATE TABLE IF NOT EXISTS "session" (
        "id" text PRIMARY KEY,
        "expires_at" timestamp NOT NULL,
        "token" text NOT NULL UNIQUE,
        "created_at" timestamp NOT NULL DEFAULT now(),
        "updated_at" timestamp NOT NULL DEFAULT now(),
        "ip_address" text,
        "user_agent" text,
        "user_id" text NOT NULL REFERENCES "user"("id") ON DELETE CASCADE
      );
    `);

    // Create account table
    console.log('Creating account table...');
    await client.query(`
      CREATE TABLE IF NOT EXISTS "account" (
        "id" text PRIMARY KEY,
        "account_id" text NOT NULL,
        "provider_id" text NOT NULL,
        "user_id" text NOT NULL REFERENCES "user"("id") ON DELETE CASCADE,
        "access_token" text,
        "refresh_token" text,
        "id_token" text,
        "access_token_expires_at" timestamp,
        "refresh_token_expires_at" timestamp,
        "scope" text,
        "password" text,
        "created_at" timestamp NOT NULL DEFAULT now(),
        "updated_at" timestamp NOT NULL DEFAULT now(),
        UNIQUE("provider_id", "account_id")
      );
    `);

    // Create verification table
    console.log('Creating verification table...');
    await client.query(`
      CREATE TABLE IF NOT EXISTS "verification" (
        "id" text PRIMARY KEY,
        "identifier" text NOT NULL,
        "value" text NOT NULL,
        "expires_at" timestamp NOT NULL,
        "created_at" timestamp NOT NULL DEFAULT now(),
        "updated_at" timestamp NOT NULL DEFAULT now()
      );
    `);

    // Create indexes
    console.log('Creating indexes...');
    await client.query(`CREATE INDEX IF NOT EXISTS "user_email_idx" ON "user"("email");`);
    await client.query(`CREATE INDEX IF NOT EXISTS "session_token_idx" ON "session"("token");`);
    await client.query(`CREATE INDEX IF NOT EXISTS "session_user_id_idx" ON "session"("user_id");`);
    await client.query(`CREATE INDEX IF NOT EXISTS "account_user_id_idx" ON "account"("user_id");`);
    await client.query(`CREATE INDEX IF NOT EXISTS "verification_identifier_idx" ON "verification"("identifier");`);

    console.log('✅ Database tables created successfully!');

    // Verify tables were created
    const result = await client.query(`
      SELECT table_name FROM information_schema.tables 
      WHERE table_schema = 'public' 
      AND table_name IN ('user', 'session', 'account', 'verification')
      ORDER BY table_name;
    `);

    console.log('Created tables:', result.rows.map(row => row.table_name));

  } catch (error) {
    console.error('Error creating tables:', error);
  } finally {
    await client.end();
  }
}

createTables();

