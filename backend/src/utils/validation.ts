import * as Joi from 'joi'

/**
 * Authentication schemas
 */
export const loginSchema = Joi.object({
  username: Joi.string().alphanum().min(3).max(100).required(),
  password: Joi.string().min(8).max(255).required(),
})

export const registerSchema = Joi.object({
  username: Joi.string().alphanum().min(3).max(100).required(),
  email: Joi.string().email().required(),
  password: Joi.string().min(8).max(255).required(),
  confirmPassword: Joi.string().valid(Joi.ref('password')).required(),
})

/**
 * Document schemas
 */
export const createDocumentSchema = Joi.object({
  title: Joi.string().min(1).max(255).required(),
  content: Joi.string().max(1000000).optional(),
  markdown_raw: Joi.string().max(1000000).required(),
  status: Joi.string().valid('draft', 'review', 'published').default('draft'),
  tags: Joi.array().items(Joi.string().max(50)).optional(),
})

export const updateDocumentSchema = Joi.object({
  title: Joi.string().min(1).max(255).optional(),
  content: Joi.string().max(1000000).optional(),
  markdown_raw: Joi.string().max(1000000).optional(),
  status: Joi.string().valid('draft', 'review', 'published').optional(),
  tags: Joi.array().items(Joi.string().max(50)).optional(),
})

export const changeStatusSchema = Joi.object({
  status: Joi.string().valid('draft', 'review', 'published').required(),
  reason: Joi.string().max(500).optional(),
})

/**
 * Search schemas
 */
export const searchSchema = Joi.object({
  q: Joi.string().min(2).max(200).required(),
  type: Joi.string().valid('all', 'draft', 'review', 'published').optional(),
  limit: Joi.number().min(1).max(100).default(50),
  offset: Joi.number().min(0).default(0),
})

export const listDocumentsSchema = Joi.object({
  limit: Joi.number().min(1).max(100).default(50),
  offset: Joi.number().min(0).default(0),
  status: Joi.string().valid('draft', 'review', 'published').optional(),
  tags: Joi.string().optional(),
})

/**
 * User schemas
 */
export const createUserSchema = Joi.object({
  username: Joi.string().alphanum().min(3).max(100).required(),
  email: Joi.string().email().required(),
  password: Joi.string().min(8).max(255).required(),
  role: Joi.string().valid('admin', 'user', 'viewer').default('user'),
})

export const updateUserRoleSchema = Joi.object({
  role: Joi.string().valid('admin', 'user', 'viewer').required(),
})

/**
 * Validation middleware factory
 */
export const validate = (schema: Joi.ObjectSchema) => {
  return (req: any, res: any, next: any) => {
    const { error, value } = schema.validate(req.body, {
      abortEarly: false,
      stripUnknown: true,
    })

    if (error) {
      const messages = error.details.map((detail: any) => ({
        field: detail.path.join('.'),
        message: detail.message,
      }))

      return res.status(400).json({
        success: false,
        error: {
          message: 'Validation error',
          code: 'VALIDATION_ERROR',
          details: messages,
        },
      })
    }

    req.body = value
    next()
  }
}

/**
 * Query validation middleware
 */
export const validateQuery = (schema: Joi.ObjectSchema) => {
  return (req: any, res: any, next: any) => {
    const { error, value } = schema.validate(req.query, {
      abortEarly: false,
      stripUnknown: true,
    })

    if (error) {
      const messages = error.details.map((detail: any) => ({
        field: detail.path.join('.'),
        message: detail.message,
      }))

      return res.status(400).json({
        success: false,
        error: {
          message: 'Validation error',
          code: 'VALIDATION_ERROR',
          details: messages,
        },
      })
    }

    req.query = value
    next()
  }
}
