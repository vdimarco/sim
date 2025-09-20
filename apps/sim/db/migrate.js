#!/usr/bin/env node

import { execSync } from 'child_process'

async function runMigrations() {
  try {
    const connectionString = process.env.DATABASE_URL
    if (!connectionString) {
      throw new Error('DATABASE_URL environment variable is required')
    }

    console.log('Connecting to database...')
    console.log('Running migrations...')

    // Use drizzle-kit directly
    const result = execSync('bunx drizzle-kit migrate', {
      encoding: 'utf8',
      stdio: 'inherit',
      env: { ...process.env, DATABASE_URL: connectionString },
    })

    console.log('Migrations completed successfully!')
    process.exit(0)
  } catch (error) {
    console.error('Migration failed:', error.message)
    process.exit(1)
  }
}

runMigrations()
