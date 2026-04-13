import env from 'dotenv'
import logger from './logger'

env.config()

const requiredEnvVars = [
  'NODE_ENV',
  'POSTGRES_URL',
  'NEO4J_BOLT_URL',
  'JWT_SECRET',
  'PORT',
]

const optionalEnvVars = [
  'LOG_LEVEL',
  'JWT_EXPIRY',
  'REFRESH_TOKEN_EXPIRY',
  'REDIS_HOST',
  'REDIS_PORT',
]

interface EnvConfig {
  NODE_ENV: string
  PORT: number
  LOG_LEVEL: string
  POSTGRES_URL: string
  NEO4J_BOLT_URL: string
  NEO4J_USER: string
  NEO4J_PASSWORD: string
  JWT_SECRET: string
  JWT_EXPIRY: string
  REFRESH_TOKEN_EXPIRY: string
  REDIS_HOST?: string
  REDIS_PORT?: number
  CORS_ORIGIN?: string
}

export const validateEnv = (): EnvConfig => {
  const missing = requiredEnvVars.filter((v) => !process.env[v])

  if (missing.length > 0) {
    const message = `Missing required environment variables: ${missing.join(', ')}`
    logger.error(message)
    throw new Error(message)
  }

  logger.info('All required environment variables are set')

  return {
    NODE_ENV: process.env.NODE_ENV || 'production',
    PORT: parseInt(process.env.PORT || '3001', 10),
    LOG_LEVEL: process.env.LOG_LEVEL || 'info',
    POSTGRES_URL: process.env.POSTGRES_URL!,
    NEO4J_BOLT_URL: process.env.NEO4J_BOLT_URL!,
    NEO4J_USER: process.env.NEO4J_USER || 'neo4j',
    NEO4J_PASSWORD: process.env.NEO4J_PASSWORD || 'neo4j',
    JWT_SECRET: process.env.JWT_SECRET!,
    JWT_EXPIRY: process.env.JWT_EXPIRY || '7d',
    REFRESH_TOKEN_EXPIRY: process.env.REFRESH_TOKEN_EXPIRY || '30d',
    REDIS_HOST: process.env.REDIS_HOST,
    REDIS_PORT: process.env.REDIS_PORT ? parseInt(process.env.REDIS_PORT, 10) : undefined,
    CORS_ORIGIN: process.env.CORS_ORIGIN,
  }
}
