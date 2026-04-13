#!/usr/bin/env node

/**
 * Database Rollback Script
 * Rollback last migration
 */

import pg from 'pg'
import fs from 'fs'
import path from 'path'
import logger from './src/utils/logger'

const client = new pg.Client({
  connectionString: process.env.POSTGRES_URL || 'postgresql://nexus_user:nexus_password@localhost:5432/nexus_db',
})

const rollback = async () => {
  try {
    await client.connect()
    logger.info('Connected to database')

    // Get last executed migration
    const result = await client.query(
      `SELECT version, name FROM nexus.schema_migrations 
       ORDER BY version DESC LIMIT 1`
    )

    if (result.rows.length === 0) {
      logger.info('No migrations to rollback')
      return
    }

    const { version, name } = result.rows[0]

    // Try to find rollback SQL file
    const rollbackFile = path.join(
      __dirname,
      'migrations',
      `${String(version).padStart(3, '0')}_${name}_rollback.sql`
    )

    if (!fs.existsSync(rollbackFile)) {
      logger.warn(`No rollback file found for migration ${version}`)
      
      // Option: Delete from migration table (destructive)
      const proceed = process.argv.includes('--force')
      if (!proceed) {
        logger.info('Use --force flag to remove migration record without rollback script')
        return
      }
    }

    await client.query('BEGIN')

    if (fs.existsSync(rollbackFile)) {
      const sql = fs.readFileSync(rollbackFile, 'utf-8')
      await client.query(sql)
      logger.info(`✓ Executed rollback for migration ${version}`)
    }

    // Remove from migrations table
    await client.query('DELETE FROM nexus.schema_migrations WHERE version = $1', [version])

    await client.query('COMMIT')
    logger.info(`✓ Migration ${version} rolled back successfully`)
  } catch (error) {
    await client.query('ROLLBACK')
    logger.error(`Rollback failed: ${error}`)
    process.exit(1)
  } finally {
    await client.end()
  }
}

rollback()
