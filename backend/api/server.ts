/**
 * Project Nexus - Backend API Server (TypeScript)
 * Express.js REST API + WebSocket Server
 * Enterprise-grade with authentication, logging, validation, rate limiting
 */

import express, { Express, Request, Response, NextFunction } from 'express'
import cors from 'cors'
import helmet from 'helmet'
import morgan from 'morgan'
import { Pool } from 'pg'
import neo4j from 'neo4j-driver'
import { v4 as uuidv4 } from 'uuid'
import expressWs from 'express-ws'
import { validateEnv } from '../src/utils/config'
import logger from '../src/utils/logger'
import { errorHandler, asyncHandler, AppError } from '../src/utils/errors'
import { authenticateToken, requireUser, requireAdmin } from '../src/middleware/auth'
import { apiLimiter, loginLimiter, createLimiter, searchLimiter } from '../src/middleware/rateLimiter'
import { validate, validateQuery, loginSchema, createDocumentSchema, updateDocumentSchema, searchSchema, listDocumentsSchema } from '../src/utils/validation'
import { successResponse, paginatedResponse, errorResponse } from '../src/utils/response'
import { sanitizeHtml, sanitizeMarkdown } from '../src/utils/sanitization'
import { createAuthRoutes } from './auth-routes'

// Initialize environment
const config = validateEnv()

// Database Connections
const pgPool = new Pool({
  connectionString: config.POSTGRES_URL,
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
})

const neo4jDriver = neo4j.driver(
  config.NEO4J_BOLT_URL,
  neo4j.auth.basic(config.NEO4J_USER, config.NEO4J_PASSWORD)
)

// Express App Setup
const app = express()
expressWs(app)

// Middleware Stack
app.use(helmet())
app.use(cors({ origin: config.CORS_ORIGIN || true }))
app.use(morgan('combined', { stream: { write: (msg) => logger.http(msg) } }))
app.use(express.json({ limit: '50mb' }))
app.use(express.urlencoded({ extended: true, limit: '50mb' }))
app.use(apiLimiter)

// ============================================================================
// HEALTH CHECK & STATUS
// ============================================================================

app.get('/health', asyncHandler(async (req: Request, res: Response) => {
  try {
    await pgPool.query('SELECT NOW()')
    const neo4jSession = neo4jDriver.session()
    await neo4jSession.run('RETURN 1')
    neo4jSession.close()

    res.json(
      successResponse({
        status: 'healthy',
        uptime: process.uptime(),
        postgres: 'connected',
        neo4j: 'connected',
        environment: config.NODE_ENV,
      })
    )
  } catch (error) {
    logger.error(`Health check failed: ${error}`)
    res.status(503).json({
      success: false,
      status: 'unhealthy',
      error: error instanceof Error ? error.message : 'Unknown error',
    })
  }
}))

// ============================================================================
// AUTHENTICATION ROUTES
// ============================================================================

const authRoutes = createAuthRoutes(pgPool)
app.use('/api/auth', authRoutes)

// ============================================================================
// DOCUMENT ENDPOINTS
// ============================================================================

/**
 * GET /api/documents
 * Fetch all documents with pagination & filtering
 */
app.get(
  '/api/documents',
  validateQuery(listDocumentsSchema),
  asyncHandler(async (req: Request, res: Response) => {
    const { limit = 50, offset = 0, status } = req.query

    const queryLimit = Math.min(parseInt(limit as string), 100)
    const queryOffset = parseInt(offset as string)

    let query = `SELECT id, uuid, title, status, tags, created_at, updated_at 
                 FROM nexus.documents WHERE is_deleted = FALSE`
    const params: any[] = []
    let paramCount = 1

    if (status) {
      query += ` AND status = $${paramCount}`
      params.push(status)
      paramCount++
    }

    query += ` ORDER BY updated_at DESC LIMIT $${paramCount} OFFSET $${paramCount + 1}`
    params.push(queryLimit, queryOffset)

    const result = await pgPool.query(query, params)

    // Get total count
    let countQuery = 'SELECT COUNT(*) as total FROM nexus.documents WHERE 1=1'
    const countResult = await pgPool.query(countQuery)

    res.json(
      paginatedResponse(
        result.rows,
        parseInt(countResult.rows[0].total),
        queryLimit,
        queryOffset,
        { method: 'GET', path: '/api/documents' }
      )
    )
  })
)

/**
 * GET /api/documents/:id
 * Fetch single document with full content
 */
app.get(
  '/api/documents/:id',
  asyncHandler(async (req: Request, res: Response) => {
    const { id } = req.params

    const result = await pgPool.query(
      'SELECT * FROM nexus.documents WHERE (uuid = $1 OR id = $1) AND is_deleted = FALSE',
      [id]
    )

    if (result.rows.length === 0) {
      throw new AppError('Document not found', 404, 'NOT_FOUND')
    }

    const doc = result.rows[0]

    // Get backlinks
    const backlinksResult = await pgPool.query(
      `SELECT d.id, d.uuid, d.title
       FROM nexus.documents d
       JOIN nexus.document_links dl ON d.id = dl.source_doc_id
       WHERE dl.target_doc_id = $1 AND d.is_deleted = FALSE`,
      [doc.id]
    )

    res.json({
      success: true,
      data: {
        ...doc,
        backlinks: backlinksResult.rows,
      },
    })
  })
)

/**
 * POST /api/documents
 * Create new document (requires authentication)
 */
app.post(
  '/api/documents',
  authenticateToken,
  createLimiter,
  validate(createDocumentSchema),
  asyncHandler(async (req: Request, res: Response) => {
    const { title, content, markdown_raw, status = 'draft', tags = [] } = req.body
    const uuid = uuidv4()
    // Sanitize content
    const sanitizedContent = content ? sanitizeHtml(content) : null
    const sanitizedMarkdown = sanitizeMarkdown(markdown_raw)

    const result = await pgPool.query(
      `INSERT INTO nexus.documents 
       (uuid, title, content, markdown_raw, status, created_by, created_at, updated_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
       RETURNING *`,
      [uuid, title, sanitizedContent, sanitizedMarkdown, status, req.user?.id, now, now]
    )

    // Log activity
    await pgPool.query(
      `INSERT INTO nexus.activity_log (user_id, action, resource_type, resource_id, ip_address)
       VALUES ($1, $2, $3, $4, $5)`,
      [req.user?.id, 'create_document', 'document', result.rows[0].id, req.ip]
    )

    logger.info(`Document created by user ${req.user?.id}: ${uuid}`)

    res.status(201).json(
      successResponse(result.rows[0], { method: 'POST', path: '/api/documents' })
     success: true,
      data: result.rows[0],
    })
  })
)

/**
 * PUT /api/documents/:id
 * Update document (requires authentication)
 */
app.put(
  '/api/documents/:id',
  authenticateToken,
  validate(updateDocumentSchema),
  asyncHandler(async (req: Request, res: Response) => {
    const { id } = req.params
    const { title, content, markdown_raw, status, tags } = req.body
    const now = new Date()

    // Fetch current document
    const currentDoc = await pgPool.query(
      'SELECT id, created_by FROM nexus.documents WHERE (uuid = $1 OR id = $1) AND is_deleted = FALSE',
      [id]
    )

    if (currentDoc.rows.length === 0) {
      throw new AppError('Document not found', 404, 'NOT_FOUND')
    }

    const docId = currentDoc.rows[0].id
    const createdBy = currentDoc.rows[0].created_by

    // Check authorization (owner or admin)
    if (req.user?.id !== createdBy && req.user?.role !== 'admin') {
      throw new AppError('Unauthorized', 403, 'FORBIDDEN')
    }

    // Update document
    const result = await pgPool.query(
      `UPDATE nexus.documents 
       SET title = COALESCE($1, title),
           content = COALESCE($2, content),
           markdown_raw = COALESCE($3, markdown_raw),
           status = COALESCE($4, status),
           tags = COALESCE($5, tags),
           updated_at = $6
       WHERE id = $7
       RETURNING *`,
      [title, content, markdown_raw, status, tags, now, docId]
    )

    // Extract and update wikilinks
    const wiklinkRegex = /\[\[([^\]]+)\]\]/g
    let match
    const wikilinks = []

    while ((match = wiklinkRegex.exec(markdown_raw || '')) !== null) {
      wikilinks.push(match[1])
    }

    // Clear existing links
    await pgPool.query('DELETE FROM nexus.document_links WHERE source_doc_id = $1', [docId])

    // Insert new links
    for (const wikilink of wikilinks) {
      const targetDoc = await pgPool.query(
        'SELECT id FROM nexus.documents WHERE title ILIKE $1 LIMIT 1',
        [wikilink]
      )

      if (targetDoc.rows.length > 0) {
        await pgPool.query(
          'INSERT INTO nexus.document_links (source_doc_id, target_doc_id) VALUES ($1, $2) ON CONFLICT DO NOTHING',
          [docId, targetDoc.rows[0].id]
        )
      }
    }

    // Log activity
    await pgPool.query(
      `INSERT INTO nexus.activity_log (user_id, action, resource_type, resource_id, ip_address)
       VALUES ($1, $2, $3, $4, $5)`,
      [req.user?.id, 'update_document', 'document', docId, req.ip]
    )

    logger.info(`Document updated by user ${req.user?.id}: ${id}`)

    res.json({
      success: true,
      data: result.rows[0],
    })
  })
)

/**
 * DELETE /api/documents/:id
 * Soft delete document
 */
app.delete(
  '/api/documents/:id',
  authenticateToken,
  asyncHandler(async (req: Request, res: Response) => {
    const { id } = req.params

    const currentDoc = await pgPool.query(
      'SELECT id, created_by FROM nexus.documents WHERE (uuid = $1 OR id = $1) AND is_deleted = FALSE',
      [id]
    )

    if (currentDoc.rows.length === 0) {
      throw new AppError('Document not found', 404, 'NOT_FOUND')
    }

    const docId = currentDoc.rows[0].id

    // Check authorization
    if (req.user?.id !== currentDoc.rows[0].created_by && req.user?.role !== 'admin') {
      throw new AppError('Unauthorized', 403, 'FORBIDDEN')
    }

    // Soft delete
    await pgPool.query(
      'UPDATE nexus.documents SET is_deleted = TRUE, deleted_at = NOW() WHERE id = $1',
      [docId]
    )

    // Log activity
    await pgPool.query(
      `INSERT INTO nexus.activity_log (user_id, action, resource_type, resource_id, ip_address)
       VALUES ($1, $2, $3, $4, $5)`,
      [req.user?.id, 'delete_document', 'document', docId, req.ip]
    )

    logger.info(`Document deleted by user ${req.user?.id}: ${id}`)

    res.json({
      success: true,
      data: { message: 'Document deleted successfully' },
    })
  })
)

// ============================================================================
// GRAPH & NAVIGATION ENDPOINTS
// ============================================================================

/**
 * GET /api/graph/neighborhood/:id
 * Get knowledge graph local neighborhood
 */
app.get(
  '/api/graph/neighborhood/:id',
  asyncHandler(async (req: Request, res: Response) => {
    const { id } = req.params
    const { depth = 1 } = req.query
    const neo4jSession = neo4jDriver.session()

    try {
      const result = await neo4jSession.run(
        `MATCH (center:Document {uuid: $uuid})
         MATCH path = (center)-[*0..$depth]-(neighbor:Document)
         RETURN {
           center: {
             uuid: center.uuid,
             title: center.title,
             centrality: center.centrality
           },
           neighbors: collect(distinct {
             uuid: neighbor.uuid,
             title: neighbor.title,
             centrality: neighbor.centrality,
             inlinks: neighbor.inlink_count,
             outlinks: neighbor.outlink_count
           }),
           links: collect(distinct {
             source: startNode(last(nodes(path))).uuid,
             target: endNode(last(nodes(path))).uuid
           })
         }`,
        { uuid: id, depth: parseInt(depth as string) }
      )

      if (result.records.length === 0) {
        throw new AppError('Document not found in graph', 404, 'NOT_FOUND')
      }

      res.json({
        success: true,
        data: result.records[0].get(0),
      })
    } finally {
      neo4jSession.close()
    }
  })
)

/**
 * GET /api/graph/centrality
 * Get hub documents (highest centrality)
 */
app.get(
  '/api/graph/centrality',
  asyncHandler(async (req: Request, res: Response) => {
    const { limit = 20 } = req.query
    const neo4jSession = neo4jDriver.session()

    try {
      const result = await neo4jSession.run(
        `MATCH (d:Document)
         RETURN d.title as title, d.uuid as uuid, d.centrality as centrality
         ORDER BY centrality DESC
         LIMIT $limit`,
        { limit: parseInt(limit as string) }
      )

      const hubs = result.records.map((record) => ({
        title: record.get('title'),
        uuid: record.get('uuid'),
        centrality: record.get('centrality'),
      }))

      res.json({
        success: true,
        data: hubs,
      })
    } finally {
      neo4jSession.close()
    }
  })
)

// ============================================================================
// SEARCH ENDPOINTS
// ============================================================================

/**
 * GET /api/search
 * Full-text search
 */
app.get(
  '/api/search',
  searchLimiter,
  validateQuery(searchSchema),
  asyncHandler(async (req: Request, res: Response) => {
    const { q, type = 'all', limit = 50, offset = 0 } = req.query

    let query = `SELECT id, uuid, title, status, 
                        ts_rank(to_tsvector('english', title || ' ' || COALESCE(content, '')), 
                                plainto_tsquery('english', $1)) as rank
                 FROM nexus.documents
                 WHERE (to_tsvector('english', title) @@ plainto_tsquery('english', $1)
                        OR to_tsvector('english', content) @@ plainto_tsquery('english', $1))
                 AND is_deleted = FALSE`

    const params: any[] = [q]
    let paramCount = 2

    if (type !== 'all') {
      query += ` AND status = $${paramCount}`
      params.push(type)
      paramCount++
    }

    query += ` ORDER BY rank DESC LIMIT $${paramCount} OFFSET $${paramCount + 1}`
    params.push(limit, offset)

    const result = await pgPool.query(query, params)

    res.json({
      success: true,
      results: result.rows,
      total: result.rows.length,
    })
  })
)

// ============================================================================
// WEBSOCKET: REAL-TIME COLLABORATION
// ============================================================================

interface CollabConnection {
  ws: any
  userId: number
  username: string
  connectedAt: Date
}

const activeConnections = new Map<string, Set<CollabConnection>>()

app.ws('/ws/collaborate/:docId', (ws: any, req: Request) => {
  const { docId } = req.params
  const userId = (req.user as any)?.id || null
  const username = (req.user as any)?.username || 'anonymous'

  if (!userId) {
    ws.close(4001, 'Unauthorized')
    return
  }

  // Add to active connections
  if (!activeConnections.has(docId)) {
    activeConnections.set(docId, new Set())
  }

  const connection: CollabConnection = { ws, userId, username, connectedAt: new Date() }
  activeConnections.get(docId)!.add(connection)

  logger.info(`User ${username} (${userId}) connected to document ${docId}`)

  // Broadcast user list
  const broadcastUserList = () => {
    const users = Array.from(activeConnections.get(docId) || []).map((conn) => ({
      userId: conn.userId,
      username: conn.username,
      connectedAt: conn.connectedAt,
    }))

    activeConnections.get(docId)?.forEach((conn) => {
      if (conn.ws.readyState === 1) {
        conn.ws.send(JSON.stringify({ type: 'userList', users }))
      }
    })
  }

  broadcastUserList()

  // Handle incoming messages
  ws.on('message', async (message: string) => {
    try {
      const data = JSON.parse(message)

      switch (data.type) {
        case 'edit':
          // Broadcast edit to other users
          activeConnections.get(docId)?.forEach((conn) => {
            if (conn.ws !== ws && conn.ws.readyState === 1) {
              conn.ws.send(
                JSON.stringify({
                  type: 'remoteEdit',
                  userId,
                  username,
                  content: data.content,
                  cursor: data.cursor,
                  timestamp: new Date(),
                })
              )
            }
          })
          break

        case 'ping':
          ws.send(JSON.stringify({ type: 'pong' }))
          break
      }
    } catch (error) {
      logger.error(`WebSocket message error: ${error}`)
      ws.send(JSON.stringify({ type: 'error', message: 'Invalid message format' }))
    }
  })

  // Handle disconnect
  ws.on('close', () => {
    activeConnections.get(docId)?.delete(connection)
    if (activeConnections.get(docId)?.size === 0) {
      activeConnections.delete(docId)
    }
    broadcastUserList()
    logger.info(`User ${username} (${userId}) disconnected from document ${docId}`)
  })

  // Handle errors
  ws.on('error', (error: Error) => {
    logger.error(`WebSocket error for user ${username}: ${error}`)
  })
})

// ============================================================================
// ERROR HANDLING & 404
// ============================================================================

app.use((req: Request, res: Response) => {
  res.status(404).json({
    success: false,
    error: {
      message: 'Route not found',
      code: 'NOT_FOUND',
      path: req.path,
      method: req.method,
    },
  })
})

app.use(errorHandler)

// ============================================================================
// SERVER STARTUP
// ============================================================================

const startServer = async () => {
  try {
    // Test database connections
    await pgPool.query('SELECT NOW()')
    logger.info('PostgreSQL connected')

    const neo4jSession = neo4jDriver.session()
    await neo4jSession.run('RETURN 1')
    neo4jSession.close()
    logger.info('Neo4j connected')

    const server = app.listen(config.PORT, () => {
      logger.info(
        `🚀 Nexus Backend Server running on port ${config.PORT} (${config.NODE_ENV})`
      )
    })

    // Graceful shutdown
    process.on('SIGTERM', async () => {
      logger.info('SIGTERM received, shutting down gracefully')
      server.close(async () => {
        await pgPool.end()
        await neo4jDriver.close()
        logger.info('Server stopped')
        process.exit(0)
      })
    })
  } catch (error) {
    logger.error(`Failed to start server: ${error}`)
    process.exit(1)
  }
}

startServer()

export default app
