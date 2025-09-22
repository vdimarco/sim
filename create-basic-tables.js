// Create basic tables for registration
const fs = require('fs');

async function createTables() {
  try {
    // Import the database connection from the app
    const { db } = require('/app/apps/sim/db');
    
    console.log('Creating basic tables for registration...');
    
    // Read the SQL file
    const sqlContent = fs.readFileSync('/tmp/create-tables.sql', 'utf8');
    
    // Split by semicolon and execute each statement
    const statements = sqlContent.split(';').filter(stmt => stmt.trim());
    
    for (const statement of statements) {
      if (statement.trim()) {
        try {
          console.log('Executing:', statement.substring(0, 50) + '...');
          await db.execute(statement);
          console.log('✓ Success');
        } catch (error) {
          console.error('Error executing statement:', error.message);
        }
      }
    }
    
    console.log('Basic tables created successfully!');
    
  } catch (error) {
    console.error('Error creating tables:', error);
  }
}

createTables();
