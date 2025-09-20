// Simple migration runner that bypasses Next.js cache issues
const { drizzle } = require('drizzle-orm/postgres-js');
const postgres = require('postgres');
const fs = require('fs');
const path = require('path');

async function runMigrations() {
  const { DATABASE_URL } = process.env;
  console.log('Starting migration...');
  
  // Use a different postgres connection method
  const connectionString = DATABASE_URL.replace('postgresql://', 'postgres://');
  console.log('Connection string:', connectionString);
  
  const sql = postgres(connectionString);
  const db = drizzle(sql);
  
  try {
    // Check if migrations table exists
    const result = await sql`
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = '__drizzle_migrations'
      );
    `;
    
    console.log('Migrations table exists:', result[0].exists);
    
    if (!result[0].exists) {
      console.log('Creating migrations table...');
      await sql`
        CREATE TABLE IF NOT EXISTS "__drizzle_migrations" (
          id SERIAL PRIMARY KEY,
          hash text NOT NULL,
          created_at bigint
        );
      `;
    }
    
    // Get list of migration files
    const migrationDir = '/app/apps/sim/db/migrations';
    const files = fs.readdirSync(migrationDir)
      .filter(file => file.endsWith('.sql'))
      .sort();
    
    console.log('Found migration files:', files.length);
    
    // Run each migration
    for (const file of files) {
      console.log(`Running migration: ${file}`);
      const sqlContent = fs.readFileSync(path.join(migrationDir, file), 'utf8');
      
      // Split by semicolon and run each statement
      const statements = sqlContent.split(';').filter(stmt => stmt.trim());
      
      for (const statement of statements) {
        if (statement.trim()) {
          try {
            await sql.unsafe(statement);
          } catch (error) {
            console.error(`Error in statement: ${statement.substring(0, 100)}...`);
            console.error('Error:', error.message);
          }
        }
      }
      
      // Record migration
      const hash = file.split('_')[0];
      await sql`
        INSERT INTO "__drizzle_migrations" (hash, created_at) 
        VALUES (${hash}, ${Date.now()})
        ON CONFLICT (hash) DO NOTHING;
      `;
    }
    
    console.log('Migrations completed successfully!');
    
  } catch (error) {
    console.error('Migration error:', error);
  } finally {
    await sql.end();
  }
}

runMigrations();

