import rateLimit from 'express-rate-limit'
import RedisStore from 'rate-limit-redis'
import redis from 'redis'
import logger from '../utils/logger'

// Create Redis client for rate limiting (optional)
let redisClient: any = null

try {
  redisClient = redis.createClient({
    host: process.env.REDIS_HOST || 'localhost',
    port: parseInt(process.env.REDIS_PORT || '6379'),
  })
  redisClient.connect()
  logger.info('Connected to Redis for rate limiting')
} catch (error) {
  logger.warn('Redis not available, using in-memory store for rate limiting')
}

/**
 * General API rate limiter (100 requests per 15 minutes)
 */
export const apiLimiter = rateLimit({
  ...(redisClient && { store: new RedisStore({ client: redisClient, prefix: 'rl:api:' }) }),
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100,
  message: 'Too many requests, please try again later',
  standardHeaders: true,
  legacyHeaders: false,
})

/**
 * Login rate limiter (5 attempts per 15 minutes)
 */
export const loginLimiter = rateLimit({
  ...(redisClient && { store: new RedisStore({ client: redisClient, prefix: 'rl:login:' }) }),
  windowMs: 15 * 60 * 1000,
  max: 5,
  skipSuccessfulRequests: true,
  message: 'Too many login attempts, please try again later',
})

/**
 * Create rate limiter (10 per hour)
 */
export const createLimiter = rateLimit({
  ...(redisClient && { store: new RedisStore({ client: redisClient, prefix: 'rl:create:' }) }),
  windowMs: 60 * 60 * 1000, // 1 hour
  max: 10,
  message: 'Too many documents created, please try again later',
})

/**
 * Search rate limiter (30 per minute)
 */
export const searchLimiter = rateLimit({
  ...(redisClient && { store: new RedisStore({ client: redisClient, prefix: 'rl:search:' }) }),
  windowMs: 60 * 1000, // 1 minute
  max: 30,
  message: 'Too many search requests, please try again later',
})
