/**
 * API Response Wrapper
 * Standardized response format for all endpoints
 */

export interface ApiResponse<T = any> {
  success: boolean
  data?: T
  error?: {
    message: string
    code: string
    details?: any
  }
  meta?: {
    timestamp: string
    path: string
    method: string
  }
}

/**
 * Create success response
 */
export const successResponse = <T>(data: T, meta?: any): ApiResponse<T> => ({
  success: true,
  data,
  meta: {
    timestamp: new Date().toISOString(),
    ...meta,
  },
})

/**
 * Create error response
 */
export const errorResponse = (
  message: string,
  code: string = 'INTERNAL_ERROR',
  details?: any,
  meta?: any
): ApiResponse => ({
  success: false,
  error: {
    message,
    code,
    details,
  },
  meta: {
    timestamp: new Date().toISOString(),
    ...meta,
  },
})

/**
 * Create paginated response
 */
export const paginatedResponse = <T>(
  data: T[],
  total: number,
  limit: number,
  offset: number,
  meta?: any
): ApiResponse<{ items: T[]; pagination: { total: number; limit: number; offset: number } }> => ({
  success: true,
  data: {
    items: data,
    pagination: { total, limit, offset },
  },
  meta: {
    timestamp: new Date().toISOString(),
    ...meta,
  },
})
