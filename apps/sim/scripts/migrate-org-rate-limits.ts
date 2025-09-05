#!/usr/bin/env tsx

/**
 * Script to migrate rate limit records from user-based to organization-based pooling
 * for members of organizations with team/enterprise subscriptions.
 *
 * Usage:
 *   # Dry run (see what would be changed):
 *   bun run scripts/migrate-org-rate-limits.ts
 *
 *   # Actually perform the migration:
 *   bun run scripts/migrate-org-rate-limits.ts --execute
 *
 * Note: Make sure you have the proper database connection configured
 */

import 'dotenv/config'
import { and, eq, inArray } from 'drizzle-orm'
import { db } from '../db'
import { member, subscription, userRateLimits } from '../db/schema'
import { createLogger } from '../lib/logs/console/logger'

const logger = createLogger('RateLimitMigration')

interface MigrationTarget {
  userId: string
  organizationId: string
  plan: string
  currentReferenceId: string
  syncRequests: number
  asyncRequests: number
  windowStart: Date
}

async function findRecordsToMigrate(): Promise<MigrationTarget[]> {
  try {
    // Find all users who are members of organizations with team/enterprise subscriptions
    const orgMembersWithSubs = await db
      .select({
        userId: member.userId,
        organizationId: member.organizationId,
        plan: subscription.plan,
      })
      .from(member)
      .innerJoin(subscription, eq(subscription.referenceId, member.organizationId))
      .where(
        and(eq(subscription.status, 'active'), inArray(subscription.plan, ['team', 'enterprise']))
      )

    if (orgMembersWithSubs.length === 0) {
      return []
    }

    // Get the user IDs
    const userIds = orgMembersWithSubs.map((m) => m.userId)

    // Find rate limit records for these users
    // Note: Using the old column name 'userId' since migration hasn't run yet
    const rateLimitRecords = await db
      .select()
      .from(userRateLimits)
      .where(inArray((userRateLimits as any).userId || userRateLimits.referenceId, userIds))

    // Combine the data
    const targets: MigrationTarget[] = []
    for (const record of rateLimitRecords) {
      const recordUserId = (record as any).userId || record.referenceId
      const memberInfo = orgMembersWithSubs.find((m) => m.userId === recordUserId)
      if (memberInfo) {
        targets.push({
          userId: memberInfo.userId,
          organizationId: memberInfo.organizationId,
          plan: memberInfo.plan,
          currentReferenceId: recordUserId,
          syncRequests: record.syncApiRequests,
          asyncRequests: record.asyncApiRequests,
          windowStart: record.windowStart,
        })
      }
    }

    return targets
  } catch (error) {
    logger.error('Error finding records to migrate:', error)
    throw error
  }
}

async function performMigration(targets: MigrationTarget[]): Promise<void> {
  let successCount = 0
  let errorCount = 0

  for (const target of targets) {
    try {
      // Delete the user-based rate limit record
      // Note: Using the old column name 'userId' since migration hasn't run yet
      await db
        .delete(userRateLimits)
        .where(eq((userRateLimits as any).userId || userRateLimits.referenceId, target.userId))

      logger.info(
        `Deleted rate limit record for user ${target.userId} (org: ${target.organizationId})`
      )
      successCount++
    } catch (error) {
      logger.error(`Failed to delete record for user ${target.userId}:`, error)
      errorCount++
    }
  }

  logger.info(`Migration complete: ${successCount} successful, ${errorCount} errors`)
}

async function main() {
  const isExecute = process.argv.includes('--execute')

  console.log('========================================')
  console.log('Rate Limit Migration Script')
  console.log(`Mode: ${isExecute ? '🚀 EXECUTE' : '👀 DRY RUN'}`)
  console.log('========================================')
  console.log('This script migrates rate limit records for')
  console.log('organization members from individual to')
  console.log('organization-level pooling.')
  console.log('========================================\n')

  try {
    // Find all records that need migration
    const targets = await findRecordsToMigrate()

    if (targets.length === 0) {
      console.log('✅ No records need migration. All rate limits are correctly configured.\n')
      process.exit(0)
    }

    // Group by organization for better visibility
    const byOrg = targets.reduce(
      (acc, target) => {
        if (!acc[target.organizationId]) {
          acc[target.organizationId] = []
        }
        acc[target.organizationId].push(target)
        return acc
      },
      {} as Record<string, MigrationTarget[]>
    )

    console.log(`Found ${targets.length} rate limit records to migrate:\n`)

    // Display what will be migrated
    for (const [orgId, orgTargets] of Object.entries(byOrg)) {
      const plan = orgTargets[0].plan
      console.log(`📁 Organization: ${orgId} (${plan} plan)`)
      console.log(`   Members affected: ${orgTargets.length}`)

      for (const target of orgTargets) {
        console.log(`   - User ${target.userId}:`)
        console.log(
          `     Current: ${target.syncRequests} sync, ${target.asyncRequests} async requests`
        )
        console.log(`     Window: ${target.windowStart.toISOString()}`)
      }
      console.log()
    }

    if (isExecute) {
      console.log('🔄 Starting migration...\n')
      await performMigration(targets)

      console.log('\n✅ Migration completed!')
      console.log(
        'Note: New requests from these users will create organization-pooled rate limit records.\n'
      )
    } else {
      console.log('ℹ️  This is a DRY RUN. No changes were made.')
      console.log('To execute the migration, run:')
      console.log('  tsx scripts/migrate-org-rate-limits.ts --execute\n')
    }

    // Summary
    console.log('========================================')
    console.log('Summary:')
    console.log(`- Organizations affected: ${Object.keys(byOrg).length}`)
    console.log(`- User records to migrate: ${targets.length}`)
    console.log('========================================\n')
  } catch (error) {
    logger.error('Migration failed:', error)
    process.exit(1)
  }
}

// Run the script
main().catch((error) => {
  console.error('Unhandled error:', error)
  process.exit(1)
})
