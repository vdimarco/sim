// Check if database tables exist
const { db } = require('/app/apps/sim/db');

async function checkTables() {
  try {
    const result = await db.execute(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' 
      AND table_name IN ('user', 'session', 'account', 'verification') 
      ORDER BY table_name;
    `);
    
    console.log('Query result:', result);
    
    if (Array.isArray(result)) {
      console.log('Tables found:', result.map(r => r.table_name));
      if (result.length === 0) {
        console.log('No tables found - this is the problem!');
      } else {
        console.log('All required tables exist');
      }
    } else if (result.rows) {
      console.log('Tables found:', result.rows.map(r => r.table_name));
      if (result.rows.length === 0) {
        console.log('No tables found - this is the problem!');
      } else {
        console.log('All required tables exist');
      }
    } else {
      console.log('Unexpected result format:', typeof result);
    }
    
  } catch (error) {
    console.error('Error checking tables:', error.message);
  }
}

checkTables();

