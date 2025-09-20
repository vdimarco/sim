import { NextResponse } from 'next/server'
import { createLogger } from '@/lib/logs/console/logger'
import { db } from '@/db'
import { permissions, workflow, workflowBlocks, workspace } from '@/db/schema'

const logger = createLogger('Health')

export async function GET() {
  try {
    const startedAt = Date.now()

    // Connectivity check: simple queries against critical tables
    const checks: Record<string, { ok: boolean; error?: string }> = {
      dbConnection: { ok: true },
      table_workspace: { ok: true },
      table_permissions: { ok: true },
      table_workflow: { ok: true },
      table_workflow_blocks: { ok: true },
    }

    try {
      // Ping DB by running a trivial select on each table
      await db.select().from(workspace).limit(1)
    } catch (error) {
      checks.dbConnection = { ok: false, error: error instanceof Error ? error.message : 'unknown' }
    }

    try {
      await db.select().from(workspace).limit(1)
    } catch (error) {
      checks.table_workspace = {
        ok: false,
        error: error instanceof Error ? error.message : 'missing or unreadable',
      }
    }

    try {
      await db.select().from(permissions).limit(1)
    } catch (error) {
      checks.table_permissions = {
        ok: false,
        error: error instanceof Error ? error.message : 'missing or unreadable',
      }
    }

    try {
      await db.select().from(workflow).limit(1)
    } catch (error) {
      checks.table_workflow = {
        ok: false,
        error: error instanceof Error ? error.message : 'missing or unreadable',
      }
    }

    try {
      await db.select().from(workflowBlocks).limit(1)
    } catch (error) {
      checks.table_workflow_blocks = {
        ok: false,
        error: error instanceof Error ? error.message : 'missing or unreadable',
      }
    }

    const allOk = Object.values(checks).every((c) => c.ok)
    const durationMs = Date.now() - startedAt

    const body = {
      status: allOk ? 'healthy' : 'degraded',
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
      durationMs,
      checks,
    }

    return NextResponse.json(body, { status: allOk ? 200 : 503 })
  } catch (error) {
    logger.error('Health check failed', { error })
    return NextResponse.json(
      {
        status: 'unhealthy',
        timestamp: new Date().toISOString(),
        error: error instanceof Error ? error.message : 'Unknown error',
      },
      { status: 500 }
    )
  }
}
