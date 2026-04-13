#!/usr/bin/env node

/**
 * Database Seed Script
 * Initialize database with sample data
 */

import pg from 'pg'
import { hashPassword } from '../src/utils/auth'
import logger from '../src/utils/logger'

const { Pool } = pg

const client = new Pool({
  connectionString: process.env.POSTGRES_URL || 'postgresql://nexus_user:nexus_password@localhost:5432/nexus_db',
})

const seedDatabase = async () => {
  try {
    await client.connect()
    logger.info('Connected to database')

    // Create admin user
    const adminPassword = await hashPassword('admin123')
    const adminResult = await client.query(
      `INSERT INTO nexus.users (username, email, password_hash, role)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (username) DO NOTHING
       RETURNING id, username`,
      ['admin', 'admin@example.com', adminPassword, 'admin']
    )

    if (adminResult.rows.length > 0) {
      logger.info(`✓ Admin user created: ${adminResult.rows[0].username}`)
    }

    // Create demo user
    const demoPassword = await hashPassword('demo123')
    const demoResult = await client.query(
      `INSERT INTO nexus.users (username, email, password_hash, role)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (username) DO NOTHING
       RETURNING id, username`,
      ['demo', 'demo@example.com', demoPassword, 'user']
    )

    if (demoResult.rows.length > 0) {
      logger.info(`✓ Demo user created: ${demoResult.rows[0].username}`)
    }

    // Create sample documents
    const samples = [
      {
        title: 'Welcome to Nexus',
        content: '<p>Welcome to Project Nexus, your enterprise knowledge management system.</p>',
        markdown_raw: '# Welcome to Nexus\n\nWelcome to Project Nexus, your enterprise knowledge management system.',
        tags: ['welcome', 'intro'],
      },
      {
        title: 'Getting Started',
        content: '<p>Guide to getting started with Nexus.</p>',
        markdown_raw: '# Getting Started\n\nGuide to [[Welcome to Nexus|getting started]] with Nexus.',
        tags: ['guide'],
      },
      {
        title: 'Architecture',
        content: '<p>System architecture overview.</p>',
        markdown_raw: '# Architecture\n\nNexus combines [[Getting Started|multiple systems]].',
        tags: ['architecture', 'technical'],
      },
    ]

    for (const sample of samples) {
      const result = await client.query(
        `INSERT INTO nexus.documents 
         (uuid, title, content, markdown_raw, status, created_by, created_at, updated_at)
         VALUES (uuid_generate_v4(), $1, $2, $3, $4, $5, NOW(), NOW())
         RETURNING id, uuid, title`,
        [sample.title, sample.content, sample.markdown_raw, 'published', adminResult.rows[0]?.id || 1]
      )

      logger.info(`✓ Document created: ${result.rows[0].title}`)
    }

    logger.info('✓ Database seeding completed successfully')
  } catch (error) {
    logger.error(`Seeding failed: ${error}`)
    process.exit(1)
  } finally {
    await client.end()
  }
}

seedDatabase()
