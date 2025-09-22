import type { Config } from 'drizzle-kit'

export default {
  schema: '../../packages/db/schema.ts',
  out: '../../packages/db/migrations',
  dialect: 'postgresql',
  dbCredentials: {
    // Use process.env directly so drizzle can run outside Next.js runtime
    url: (process.env.DATABASE_URL as string) || '',
  },
} satisfies Config
