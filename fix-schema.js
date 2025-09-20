// Fix database schema to match Better Auth requirements
const { db } = require('/app/apps/sim/db');

async function fixSchema() {
  try {
    console.log('Checking current schema...');
    
    // Check if organization table exists
    const orgResult = await db.execute(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' 
      AND table_name = 'organization';
    `);
    
    console.log('Organization table exists:', orgResult.length > 0);
    
    if (orgResult.length === 0) {
      console.log('Creating organization table...');
      await db.execute(`
        CREATE TABLE IF NOT EXISTS "organization" (
          "id" text PRIMARY KEY,
          "name" text NOT NULL,
          "slug" text NOT NULL UNIQUE,
          "logo" text,
          "created_at" timestamp NOT NULL DEFAULT now(),
          "updated_at" timestamp NOT NULL DEFAULT now()
        );
      `);
      console.log('✓ Organization table created');
    }
    
    // Check if session table has active_organization_id column
    const sessionColumns = await db.execute(`
      SELECT column_name 
      FROM information_schema.columns 
      WHERE table_schema = 'public' 
      AND table_name = 'session' 
      AND column_name = 'active_organization_id';
    `);
    
    console.log('active_organization_id column exists:', sessionColumns.length > 0);
    
    if (sessionColumns.length === 0) {
      console.log('Adding active_organization_id column to session table...');
      await db.execute(`
        ALTER TABLE "session" 
        ADD COLUMN "active_organization_id" text 
        REFERENCES "organization"("id") ON DELETE SET NULL;
      `);
      console.log('✓ active_organization_id column added');
    }
    
    // Check if member table exists
    const memberResult = await db.execute(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' 
      AND table_name = 'member';
    `);
    
    console.log('Member table exists:', memberResult.length > 0);
    
    if (memberResult.length === 0) {
      console.log('Creating member table...');
      await db.execute(`
        CREATE TABLE IF NOT EXISTS "member" (
          "id" text PRIMARY KEY,
          "organization_id" text NOT NULL REFERENCES "organization"("id") ON DELETE CASCADE,
          "user_id" text NOT NULL REFERENCES "user"("id") ON DELETE CASCADE,
          "role" text NOT NULL DEFAULT 'member',
          "created_at" timestamp NOT NULL DEFAULT now(),
          "updated_at" timestamp NOT NULL DEFAULT now(),
          UNIQUE("organization_id", "user_id")
        );
      `);
      console.log('✓ Member table created');
    }
    
    // Check if invitation table exists
    const invitationResult = await db.execute(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' 
      AND table_name = 'invitation';
    `);
    
    console.log('Invitation table exists:', invitationResult.length > 0);
    
    if (invitationResult.length === 0) {
      console.log('Creating invitation table...');
      await db.execute(`
        CREATE TABLE IF NOT EXISTS "invitation" (
          "id" text PRIMARY KEY,
          "organization_id" text NOT NULL REFERENCES "organization"("id") ON DELETE CASCADE,
          "email" text NOT NULL,
          "role" text NOT NULL DEFAULT 'member',
          "status" text NOT NULL DEFAULT 'pending',
          "created_at" timestamp NOT NULL DEFAULT now(),
          "updated_at" timestamp NOT NULL DEFAULT now(),
          "expires_at" timestamp NOT NULL
        );
      `);
      console.log('✓ Invitation table created');
    }
    
    console.log('✅ Database schema fixed successfully!');
    
  } catch (error) {
    console.error('Error fixing schema:', error);
  }
}

fixSchema();
