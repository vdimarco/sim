const postgres = require('postgres').default;

async function checkDatabase() {
  const { DATABASE_URL } = process.env;
  console.log('DATABASE_URL:', DATABASE_URL ? 'Set' : 'Not set');
  
  const sql = postgres(DATABASE_URL);
  
  try {
    const tables = await sql`SELECT table_name FROM information_schema.tables WHERE table_schema = 'public'`;
    console.log('Existing tables:', tables);
    
    if (tables.length === 0) {
      console.log('No tables found - database schema not created');
    } else {
      console.log('Database has', tables.length, 'tables');
    }
  } catch (error) {
    console.error('Database error:', error.message);
  } finally {
    await sql.end();
  }
}

checkDatabase();
