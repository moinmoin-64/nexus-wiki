import { Router, Request, Response } from 'express'
import { Pool } from 'pg'
import { authenticateUser, refreshAccessToken, revokeRefreshToken, hashPassword } from '../utils/auth'
import { validate, loginSchema, registerSchema } from '../utils/validation'
import { loginLimiter } from '../middleware/rateLimiter'
import { asyncHandler, AppError } from '../utils/errors'
import { authenticateToken } from '../middleware/auth'
import logger from '../utils/logger'

export const createAuthRoutes = (pgPool: Pool): Router => {
  const router = Router()

  /**
   * POST /api/auth/login
   * Authenticate user and return JWT tokens
   */
  router.post(
    '/login',
    loginLimiter,
    validate(loginSchema),
    asyncHandler(async (req: Request, res: Response) => {
      const { username, password } = req.body

      const authResponse = await authenticateUser(pgPool, username, password)

      // Set secure cookies (optional)
      res.cookie('access_token', authResponse.access_token, {
        httpOnly: true,
        secure: process.env.NODE_ENV === 'production',
        sameSite: 'strict',
        maxAge: 7 * 24 * 60 * 60 * 1000, // 7 days
      })

      res.cookie('refresh_token', authResponse.refresh_token, {
        httpOnly: true,
        secure: process.env.NODE_ENV === 'production',
        sameSite: 'strict',
        maxAge: 30 * 24 * 60 * 60 * 1000, // 30 days
      })

      res.json({
        success: true,
        data: authResponse,
      })
    })
  )

  /**
   * POST /api/auth/register
   * Register new user
   */
  router.post(
    '/register',
    validate(registerSchema),
    asyncHandler(async (req: Request, res: Response) => {
      const { username, email, password } = req.body

      // Check if user exists
      const existingUser = await pgPool.query(
        'SELECT id FROM nexus.users WHERE username = $1 OR email = $2',
        [username, email]
      )

      if (existingUser.rows.length > 0) {
        throw new AppError('User already exists', 409, 'USER_EXISTS')
      }

      // Hash password
      const passwordHash = await hashPassword(password)

      // Create user
      const result = await pgPool.query(
        `INSERT INTO nexus.users (username, email, password_hash, role)
         VALUES ($1, $2, $3, $4)
         RETURNING id, uuid, username, email, role`,
        [username, email, passwordHash, 'user']
      )

      const newUser = result.rows[0]

      logger.info(`New user registered: ${username} (ID: ${newUser.id})`)

      res.status(201).json({
        success: true,
        data: {
          message: 'User registered successfully',
          user: newUser,
        },
      })
    })
  )

  /**
   * POST /api/auth/refresh
   * Refresh access token
   */
  router.post(
    '/refresh',
    asyncHandler(async (req: Request, res: Response) => {
      const refreshToken = req.cookies?.refresh_token || req.body?.refresh_token

      if (!refreshToken) {
        throw new AppError('No refresh token provided', 401, 'NO_REFRESH_TOKEN')
      }

      const response = await refreshAccessToken(pgPool, refreshToken)

      res.json({
        success: true,
        data: response,
      })
    })
  )

  /**
   * POST /api/auth/logout
   * Revoke tokens and logout
   */
  router.post(
    '/logout',
    authenticateToken,
    asyncHandler(async (req: Request, res: Response) => {
      const refreshToken = req.cookies?.refresh_token || req.body?.refresh_token

      if (refreshToken) {
        await revokeRefreshToken(pgPool, refreshToken)
      }

      res.clearCookie('access_token')
      res.clearCookie('refresh_token')

      logger.info(`User ${req.user?.id} logged out`)

      res.json({
        success: true,
        data: { message: 'Logged out successfully' },
      })
    })
  )

  /**
   * GET /api/auth/me
   * Get current user info
   */
  router.get(
    '/me',
    authenticateToken,
    asyncHandler(async (req: Request, res: Response) => {
      const userResult = await pgPool.query(
        'SELECT id, uuid, username, email, role, last_login, created_at FROM nexus.users WHERE id = $1',
        [req.user?.id]
      )

      if (userResult.rows.length === 0) {
        throw new AppError('User not found', 404, 'USER_NOT_FOUND')
      }

      res.json({
        success: true,
        data: { user: userResult.rows[0] },
      })
    })
  )

  /**
   * POST /api/auth/change-password
   * Change user password
   */
  router.post(
    '/change-password',
    authenticateToken,
    asyncHandler(async (req: Request, res: Response) => {
      const { currentPassword, newPassword } = req.body

      if (!currentPassword || !newPassword) {
        throw new AppError('Current and new passwords required', 400, 'MISSING_PASSWORDS')
      }

      // Get user
      const userResult = await pgPool.query(
        'SELECT password_hash FROM nexus.users WHERE id = $1',
        [req.user?.id]
      )

      if (userResult.rows.length === 0) {
        throw new AppError('User not found', 404, 'USER_NOT_FOUND')
      }

      // Verify current password
      const { comparePassword } = await import('../utils/auth')
      const isValid = await comparePassword(currentPassword, userResult.rows[0].password_hash)

      if (!isValid) {
        throw new AppError('Invalid current password', 401, 'INVALID_PASSWORD')
      }

      // Hash new password
      const newHash = await hashPassword(newPassword)

      // Update password
      await pgPool.query('UPDATE nexus.users SET password_hash = $1 WHERE id = $2', [
        newHash,
        req.user?.id,
      ])

      logger.info(`User ${req.user?.id} changed password`)

      res.json({
        success: true,
        data: { message: 'Password changed successfully' },
      })
    })
  )

  return router
}
