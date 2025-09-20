// Run SQL to create tables using the existing database connection
const fs = require('fs');

async function runSQL() {
  try {
    // Import the database connection from the app
    const { db } = require('./lib/db');
    
    console.log('Reading SQL file...');
    const sqlContent = fs.readFileSync('/tmp/create-tables.sql', 'utf8');
    
    console.log('Executing SQL...');
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
    
    console.log('✅ SQL execution completed!');
    
  } catch (error) {
    console.error('Error running SQL:', error);
  }
}

runSQL();

