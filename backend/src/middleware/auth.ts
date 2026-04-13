import { Request, Response, NextFunction } from 'express'
import { verifyToken, JWTPayload } from '../utils/auth'
import { AppError } from '../utils/errors'
import logger from '../utils/logger'

declare global {
  namespace Express {
    interface Request {
      user?: JWTPayload
      token?: string
    }
  }
}

/**
 * Middleware: Extract and verify JWT token
 */
export const authenticateToken = (req: Request, res: Response, next: NextFunction) => {
  try {
    const authHeader = req.headers['authorization']
    const token = authHeader && authHeader.split(' ')[1] // Bearer TOKEN

    if (!token) {
      throw new AppError('No token provided', 401, 'NO_TOKEN')
    }

    const decoded = verifyToken(token)
    req.user = decoded
    req.token = token
    next()
  } catch (error) {
    if (error instanceof AppError) {
      return res.status(error.status).json({
        success: false,
        error: {
          message: error.message,
          code: error.code,
        },
      })
    }
    logger.error(`Authentication middleware error: ${error}`)
    res.status(500).json({
      success: false,
      error: {
        message: 'Authentication failed',
        code: 'AUTH_FAILED',
      },
    })
  }
}

/**
 * Middleware: Require specific role
 */
export const requireRole = (roles: string[]) => {
  return (req: Request, res: Response, next: NextFunction) => {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        error: { message: 'Unauthorized', code: 'UNAUTHORIZED' },
      })
    }

    if (!roles.includes(req.user.role)) {
      logger.warn(`User ${req.user.id} attempted unauthorized action`)
      return res.status(403).json({
        success: false,
        error: { message: 'Forbidden', code: 'FORBIDDEN' },
      })
    }

    next()
  }
}

/**
 * Middleware: Admin only
 */
export const requireAdmin = requireRole(['admin'])

/**
 * Middleware: User or Admin
 */
export const requireUser = requireRole(['admin', 'user'])
