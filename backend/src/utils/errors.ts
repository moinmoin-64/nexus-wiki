import { Request, Response, NextFunction } from 'express'
import logger from './logger'

export interface ApiError extends Error {
  status?: number
  code?: string
  details?: any
}

export class AppError extends Error implements ApiError {
  status: number
  code: string
  details?: any

  constructor(message: string, status: number = 500, code: string = 'INTERNAL_ERROR', details?: any) {
    super(message)
    this.status = status
    this.code = code
    this.details = details
    Object.setPrototypeOf(this, AppError.prototype)
  }
}

export const errorHandler = (err: any, req: Request, res: Response, next: NextFunction) => {
  const status = err.status || 500
  const code = err.code || 'INTERNAL_ERROR'
  const message = err.message || 'Internal Server Error'

  logger.error({
    message,
    status,
    code,
    path: req.path,
    method: req.method,
    ip: req.ip,
    userId: req.user?.id,
    stack: err.stack,
  })

  res.status(status).json({
    success: false,
    error: {
      message,
      code,
      status,
      ...(process.env.NODE_ENV === 'development' && { details: err.details, stack: err.stack }),
    },
  })
}

export const asyncHandler = (fn: Function) => (req: Request, res: Response, next: NextFunction) => {
  Promise.resolve(fn(req, res, next)).catch(next)
}
