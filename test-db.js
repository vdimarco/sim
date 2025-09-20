// Test database connection and create tables
const { db } = require('/app/apps/sim/db');

async function testDB() {
  try {
    console.log('Testing database connection...');
    
    // Test connection
    const result = await db.execute('SELECT 1 as test');
    console.log('Database connection successful:', result);
    
    // Create user table
    console.log('Creating user table...');
    await db.execute(`
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
    console.log('✓ User table created');
    
    // Create session table
    console.log('Creating session table...');
    await db.execute(`
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
    console.log('✓ Session table created');
    
    // Create account table
    console.log('Creating account table...');
    await db.execute(`
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
    console.log('✓ Account table created');
    
    // Create verification table
    console.log('Creating verification table...');
    await db.execute(`
      CREATE TABLE IF NOT EXISTS "verification" (
        "id" text PRIMARY KEY,
        "identifier" text NOT NULL,
        "value" text NOT NULL,
        "expires_at" timestamp NOT NULL,
        "created_at" timestamp NOT NULL DEFAULT now(),
        "updated_at" timestamp NOT NULL DEFAULT now()
      );
    `);
    console.log('✓ Verification table created');
    
    console.log('✅ All tables created successfully!');
    
  } catch (error) {
    console.error('Error:', error);
  }
}

testDB();
