#!/usr/bin/env node

/**
 * Quick Start Script
 * Validates setup and provides helpful debug info
 */

import { exec } from 'child_process'
import { promisify } from 'util'
import fs from 'fs'
import path from 'path'

const execAsync = promisify(exec)

const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
}

const log = {
  success: (msg: string) => console.log(`${colors.green}✓${colors.reset} ${msg}`),
  error: (msg: string) => console.log(`${colors.red}✗${colors.reset} ${msg}`),
  info: (msg: string) => console.log(`${colors.blue}ℹ${colors.reset} ${msg}`),
  warn: (msg: string) => console.log(`${colors.yellow}⚠${colors.reset} ${msg}`),
}

async function checkCommand(cmd: string, name: string) {
  try {
    await execAsync(`${cmd} --version`)
    log.success(`${name} installed`)
    return true
  } catch {
    log.error(`${name} not found`)
    return false
  }
}

async function checkFile(filePath: string, name: string) {
  if (fs.existsSync(filePath)) {
    log.success(`${name} exists`)
    return true
  } else {
    log.warn(`${name} missing`)
    return false
  }
}

async function main() {
  console.log(`\n${colors.blue}=== Project Nexus Quick Start ===${colors.reset}\n`)

  // Check Node.js
  const nodeOk = await checkCommand('node', 'Node.js')
  if (!nodeOk) {
    log.error('Please install Node.js v18+')
    process.exit(1)
  }

  // Check npm
  await checkCommand('npm', 'npm')

  // Check PostgreSQL
  await checkCommand('psql', 'PostgreSQL client')

  // Check files
  console.log(`\n${colors.blue}File Structure:${colors.reset}\n`)
  await checkFile('backend/package.json', 'Backend package.json')
  await checkFile('frontend/package.json', 'Frontend package.json')
  await checkFile('backend/.env', 'Backend .env')
  await checkFile('frontend/.env', 'Frontend .env')

  // Check databases
  console.log(`\n${colors.blue}Database Status:${colors.reset}\n`)

  try {
    const { stdout } = await execAsync('psql -U postgres -l 2>/dev/null || echo "PostgreSQL not running"')
    if (stdout.includes('nexus_db')) {
      log.success('PostgreSQL configured')
    } else {
      log.warn('PostgreSQL may need initialization')
    }
  } catch {
    log.warn('PostgreSQL not responding')
  }

  // Recommendations
  console.log(`\n${colors.blue}Quick Start Guide:${colors.reset}\n`)
  console.log(`1. Install dependencies:
   ${colors.green}npm install${colors.reset}

2. Start backend:
   ${colors.green}cd backend && npm run dev${colors.reset}

3. Start frontend (new terminal):
   ${colors.green}cd frontend && npm run dev${colors.reset}

4. Access app:
   ${colors.green}http://localhost:5173${colors.reset}

5. Login with:
   ${colors.green}demo / demo123${colors.reset}

`)

  console.log(`${colors.blue}=== Setup Check Complete ===${colors.reset}\n`)
}

main().catch(console.error)
