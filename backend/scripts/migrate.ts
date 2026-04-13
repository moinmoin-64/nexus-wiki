#!/usr/bin/env node

/**
 * Database Migration Runner
 * Usage: npm run migrate
 */

import pg from 'pg'
import fs from 'fs'
import path from 'path'
import logger from './src/utils/logger'

const client = new pg.Client({
  connectionString: process.env.POSTGRES_URL || 'postgresql://nexus_user:nexus_password@localhost:5432/nexus_db',
})

interface Migration {
  version: number
  name: string
  content: string
}

const getMigrations = (): Migration[] => {
  const migrationsDir = path.join(__dirname, 'migrations')
  const files = fs.readdirSync(migrationsDir).filter((f) => f.endsWith('.sql'))

  return files.map((file) => {
    const match = file.match(/^(\d+)_(.+)\.sql$/)
    if (!match) throw new Error(`Invalid migration filename: ${file}`)

    const [, version, name] = match
    const content = fs.readFileSync(path.join(migrationsDir, file), 'utf-8')

    return {
      version: parseInt(version, 10),
      name,
      content,
    }
  }).sort((a, b) => a.version - b.version)
}

const initMigrationsTable = async () => {
  await client.query(`
    CREATE TABLE IF NOT EXISTS nexus.schema_migrations (
      version INTEGER PRIMARY KEY,
      name VARCHAR(255) NOT NULL,
      executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
  `)
}

const getExecutedMigrations = async (): Promise<number[]> => {
  const result = await client.query('SELECT version FROM nexus.schema_migrations ORDER BY version')
  return result.rows.map((r) => r.version)
}

const runMigration = async (migration: Migration) => {
  try {
    logger.info(`Running migration ${migration.version}: ${migration.name}`)

    await client.query('BEGIN')
    await client.query(migration.content)
    await client.query('INSERT INTO nexus.schema_migrations (version, name) VALUES ($1, $2)', [
      migration.version,
      migration.name,
    ])
    await client.query('COMMIT')

    logger.info(`✓ Migration ${migration.version} completed`)
  } catch (error) {
    await client.query('ROLLBACK')
    logger.error(`✗ Migration ${migration.version} failed: ${error}`)
    throw error
  }
}

const migrate = async () => {
  try {
    await client.connect()
    logger.info('Connected to database')

    await initMigrationsTable()
    const migrations = getMigrations()
    const executed = await getExecutedMigrations()

    const pending = migrations.filter((m) => !executed.includes(m.version))

    if (pending.length === 0) {
      logger.info('No pending migrations')
      return
    }

    logger.info(`Found ${pending.length} pending migrations`)

    for (const migration of pending) {
      await runMigration(migration)
    }

    logger.info('All migrations completed successfully')
  } catch (error) {
    logger.error(`Migration failed: ${error}`)
    process.exit(1)
  } finally {
    await client.end()
  }
}

migrate()
