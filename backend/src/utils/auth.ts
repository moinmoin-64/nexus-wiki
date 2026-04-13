import bcrypt from 'bcrypt'
import jwt from 'jsonwebtoken'
import { Pool } from 'pg'
import logger from '../utils/logger'
import { AppError } from '../utils/errors'

const SALT_ROUNDS = 12
const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production'
const JWT_EXPIRY = process.env.JWT_EXPIRY || '7d'
const REFRESH_TOKEN_EXPIRY = process.env.REFRESH_TOKEN_EXPIRY || '30d'

export interface JWTPayload {
  id: number
  uuid: string
  username: string
  role: 'admin' | 'user' | 'viewer'
  iat?: number
  exp?: number
}

export interface AuthRequest {
  username: string
  password: string
}

export interface AuthResponse {
  access_token: string
  refresh_token: string
  user: {
    id: number
    uuid: string
    username: string
    email: string
    role: string
  }
  expires_in: string
}

/**
 * Hash password with bcrypt
 */
export const hashPassword = async (password: string): Promise<string> => {
  try {
    return await bcrypt.hash(password, SALT_ROUNDS)
  } catch (error) {
    logger.error(`Password hashing failed: ${error}`)
    throw new AppError('Password hashing failed', 500, 'HASH_ERROR')
  }
}

/**
 * Compare password with hash
 */
export const comparePassword = async (password: string, hash: string): Promise<boolean> => {
  try {
    return await bcrypt.compare(password, hash)
  } catch (error) {
    logger.error(`Password comparison failed: ${error}`)
    throw new AppError('Authentication failed', 401, 'AUTH_ERROR')
  }
}

/**
 * Generate JWT access token
 */
export const generateAccessToken = (payload: JWTPayload): string => {
  return jwt.sign(payload, JWT_SECRET, {
    expiresIn: JWT_EXPIRY,
    issuer: 'nexus',
    audience: 'nexus-client',
  })
}

/**
 * Generate JWT refresh token
 */
export const generateRefreshToken = (userId: number): string => {
  return jwt.sign({ sub: userId }, JWT_SECRET, {
    expiresIn: REFRESH_TOKEN_EXPIRY,
    issuer: 'nexus',
    audience: 'nexus-client',
  })
}

/**
 * Verify JWT token
 */
export const verifyToken = (token: string): JWTPayload => {
  try {
    return jwt.verify(token, JWT_SECRET, {
      issuer: 'nexus',
      audience: 'nexus-client',
    }) as JWTPayload
  } catch (error: any) {
    if (error.name === 'TokenExpiredError') {
      throw new AppError('Token expired', 401, 'TOKEN_EXPIRED')
    }
    if (error.name === 'JsonWebTokenError') {
      throw new AppError('Invalid token', 401, 'INVALID_TOKEN')
    }
    throw new AppError('Token verification failed', 401, 'TOKEN_ERROR')
  }
}

/**
 * Authenticate user with username/password
 */
export const authenticateUser = async (
  pgPool: Pool,
  username: string,
  password: string
): Promise<AuthResponse> => {
  try {
    // Find user
    const userResult = await pgPool.query(
      'SELECT id, uuid, username, email, password_hash, role FROM nexus.users WHERE username = $1',
      [username]
    )

    if (userResult.rows.length === 0) {
      logger.warn(`Login attempt with non-existent username: ${username}`)
      throw new AppError('Invalid credentials', 401, 'INVALID_CREDENTIALS')
    }

    const user = userResult.rows[0]

    // Verify password
    const passwordValid = await comparePassword(password, user.password_hash)
    if (!passwordValid) {
      logger.warn(`Failed login attempt for user: ${username}`)
      throw new AppError('Invalid credentials', 401, 'INVALID_CREDENTIALS')
    }

    // Update last login
    await pgPool.query('UPDATE nexus.users SET last_login = NOW() WHERE id = $1', [user.id])

    // Generate tokens
    const accessToken = generateAccessToken({
      id: user.id,
      uuid: user.uuid,
      username: user.username,
      role: user.role,
    })

    const refreshToken = generateRefreshToken(user.id)

    // Store refresh token in database for revocation
    await pgPool.query(
      `INSERT INTO nexus.refresh_tokens (user_id, token, expires_at)
       VALUES ($1, $2, NOW() + INTERVAL '30 days')`,
      [user.id, refreshToken]
    )

    logger.info(`User ${username} (ID: ${user.id}) logged in successfully`)

    return {
      access_token: accessToken,
      refresh_token: refreshToken,
      user: {
        id: user.id,
        uuid: user.uuid,
        username: user.username,
        email: user.email,
        role: user.role,
      },
      expires_in: JWT_EXPIRY,
    }
  } catch (error) {
    if (error instanceof AppError) throw error
    logger.error(`Authentication error: ${error}`)
    throw new AppError('Authentication failed', 500, 'AUTH_ERROR')
  }
}

/**
 * Refresh access token
 */
export const refreshAccessToken = async (
  pgPool: Pool,
  refreshToken: string
): Promise<{ access_token: string; expires_in: string }> => {
  try {
    // Verify refresh token
    const decoded = verifyToken(refreshToken)

    // Check if token exists in database and not revoked
    const tokenResult = await pgPool.query(
      `SELECT * FROM nexus.refresh_tokens 
       WHERE user_id = $1 AND token = $2 AND revoked_at IS NULL`,
      [decoded.sub, refreshToken]
    )

    if (tokenResult.rows.length === 0) {
      throw new AppError('Invalid refresh token', 401, 'INVALID_REFRESH_TOKEN')
    }

    // Get updated user info
    const userResult = await pgPool.query(
      'SELECT id, uuid, username, role FROM nexus.users WHERE id = $1',
      [decoded.sub]
    )

    if (userResult.rows.length === 0) {
      throw new AppError('User not found', 401, 'USER_NOT_FOUND')
    }

    const user = userResult.rows[0]

    // Generate new access token
    const newAccessToken = generateAccessToken({
      id: user.id,
      uuid: user.uuid,
      username: user.username,
      role: user.role,
    })

    logger.info(`Access token refreshed for user ID: ${user.id}`)

    return {
      access_token: newAccessToken,
      expires_in: JWT_EXPIRY,
    }
  } catch (error) {
    if (error instanceof AppError) throw error
    logger.error(`Token refresh error: ${error}`)
    throw new AppError('Token refresh failed', 401, 'REFRESH_ERROR')
  }
}

/**
 * Revoke refresh token (logout)
 */
export const revokeRefreshToken = async (pgPool: Pool, refreshToken: string): Promise<void> => {
  try {
    await pgPool.query(
      `UPDATE nexus.refresh_tokens SET revoked_at = NOW() WHERE token = $1`,
      [refreshToken]
    )
    logger.info('Refresh token revoked')
  } catch (error) {
    logger.error(`Token revocation error: ${error}`)
    throw new AppError('Logout failed', 500, 'LOGOUT_ERROR')
  }
}
