/**
 * Governance & Audit Endpoints for Project Nexus
 * Add these endpoints to api/server.js
 */

// ============================================================================
// AUDIT LOG ENDPOINTS
// ============================================================================

/**
 * GET /api/audit/log
 * Retrieve audit log entries (admin only)
 */
app.get('/api/audit/log', requireAdmin, async (req, res) => {
  try {
    const { limit = 100, offset = 0, user_id, action, document_id } = req.query
    const queryLimit = Math.min(parseInt(limit), 1000)
    const queryOffset = parseInt(offset)

    let query = 'SELECT * FROM nexus.activity_log WHERE 1=1'
    const params = []
    let paramCount = 1

    if (user_id) {
      query += ` AND user_id = $${paramCount}`
      params.push(user_id)
      paramCount++
    }

    if (action) {
      query += ` AND action = $${paramCount}`
      params.push(action)
      paramCount++
    }

    if (document_id) {
      query += ` AND document_id = $${paramCount}`
      params.push(document_id)
      paramCount++
    }

    query += ` ORDER BY timestamp DESC LIMIT $${paramCount} OFFSET $${paramCount + 1}`
    params.push(queryLimit, queryOffset)

    const result = await pgPool.query(query, params)

    res.json({
      entries: result.rows,
      limit: queryLimit,
      offset: queryOffset
    })
  } catch (error) {
    res.status(500).json({ error: error.message })
  }
})

/**
 * GET /api/audit/log/:docId
 * Get audit log for specific document
 */
app.get('/api/audit/log/:docId', async (req, res) => {
  try {
    const { docId } = req.params

    const result = await pgPool.query(
      `SELECT al.*, u.username
       FROM nexus.activity_log al
       LEFT JOIN nexus.users u ON al.user_id = u.id
       WHERE al.document_id = $1
       ORDER BY al.timestamp DESC
       LIMIT 100`,
      [docId]
    )

    res.json({ history: result.rows })
  } catch (error) {
    res.status(500).json({ error: error.message })
  }
})

/**
 * POST /api/audit/log
 * Create audit log entry (internal)
 */
const createAuditLog = async (
  user_id: number,
  action: string,
  document_id: number,
  old_status?: string,
  new_status?: string,
  details?: any
) => {
  try {
    await pgPool.query(
      `INSERT INTO nexus.activity_log 
       (user_id, action, document_id, old_status, new_status, timestamp, details)
       VALUES ($1, $2, $3, $4, $5, NOW(), $6)`,
      [user_id, action, document_id, old_status, new_status, JSON.stringify(details)]
    )
  } catch (error) {
    console.error('Audit log creation failed:', error)
  }
}

// ============================================================================
// DOCUMENT WORKFLOW ENDPOINTS
// ============================================================================

/**
 * PUT /api/documents/:id/status
 * Change document status with workflow validation
 */
app.put('/api/documents/:id/status', requireAuth, async (req, res) => {
  try {
    const { id } = req.params
    const { status } = req.body
    const userId = req.user?.id

    // Validate status
    const validStatuses = ['draft', 'review', 'published']
    if (!validStatuses.includes(status)) {
      return res.status(400).json({ error: 'Invalid status' })
    }

    // Get current document
    const docResult = await pgPool.query(
      'SELECT * FROM nexus.documents WHERE uuid = $1 OR id = $1',
      [id]
    )

    if (docResult.rows.length === 0) {
      return res.status(404).json({ error: 'Document not found' })
    }

    const doc = docResult.rows[0]
    const oldStatus = doc.status

    // Check permission (users can only publish, admins can do anything)
    const userRole = req.user?.role || 'user'
    if (userRole !== 'admin' && status === 'published') {
      // Check if user created this document
      if (doc.created_by !== userId) {
        return res.status(403).json({ error: 'Permission denied' })
      }
    }

    // Update document status
    const updateResult = await pgPool.query(
      `UPDATE nexus.documents 
       SET status = $1, updated_at = NOW(), updated_by = $2
       WHERE id = $3
       RETURNING *`,
      [status, userId, doc.id]
    )

    // Log to audit trail
    await createAuditLog(
      userId,
      'CHANGE_STATUS',
      doc.id,
      oldStatus,
      status,
      { reason: req.body.reason }
    )

    // Commit to Git
    const commitMsg = `[${status.toUpperCase()}] ${doc.title} (${oldStatus} → ${status})`
    // TODO: Implement git commit

    res.json({
      success: true,
      document: updateResult.rows[0],
      message: `Document status changed to ${status}`
    })
  } catch (error) {
    res.status(500).json({ error: error.message })
  }
})

/**
 * GET /api/documents/:id/workflow
 * Get available status transitions for document
 */
app.get('/api/documents/:id/workflow', async (req, res) => {
  try {
    const { id } = req.params

    const result = await pgPool.query(
      'SELECT status FROM nexus.documents WHERE uuid = $1 OR id = $1',
      [id]
    )

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Document not found' })
    }

    const currentStatus = result.rows[0].status
    
    // Determine possible transitions
    const transitions: Record<string, string[]> = {
      draft: ['review', 'published'],
      review: ['draft', 'published'],
      published: ['review', 'draft']
    }

    res.json({
      current_status: currentStatus,
      allowed_transitions: transitions[currentStatus] || [],
      all_statuses: ['draft', 'review', 'published']
    })
  } catch (error) {
    res.status(500).json({ error: error.message })
  }
})

// ============================================================================
// USER & ROLE ENDPOINTS
// ============================================================================

/**
 * GET /api/users
 * List all users (admin only)
 */
app.get('/api/users', requireAdmin, async (req, res) => {
  try {
    const result = await pgPool.query(
      'SELECT id, uuid, username, email, role, created_at, last_login FROM nexus.users ORDER BY created_at DESC'
    )

    res.json({ users: result.rows })
  } catch (error) {
    res.status(500).json({ error: error.message })
  }
})

/**
 * POST /api/users
 * Create new user (admin only)
 */
app.post('/api/users', requireAdmin, async (req, res) => {
  try {
    const { username, email, password, role = 'user' } = req.body

    const validRoles = ['admin', 'user', 'viewer']
    if (!validRoles.includes(role)) {
      return res.status(400).json({ error: 'Invalid role' })
    }

    // Hash password (implement with bcrypt)
    const passwordHash = 'TODO_HASH'

    const result = await pgPool.query(
      `INSERT INTO nexus.users (uuid, username, email, password_hash, role, created_at)
       VALUES (gen_random_uuid(), $1, $2, $3, $4, NOW())
       RETURNING id, uuid, username, email, role`,
      [username, email, passwordHash, role]
    )

    res.status(201).json(result.rows[0])
  } catch (error) {
    res.status(500).json({ error: error.message })
  }
})

/**
 * PUT /api/users/:id/role
 * Change user role (admin only)
 */
app.put('/api/users/:id/role', requireAdmin, async (req, res) => {
  try {
    const { id } = req.params
    const { role } = req.body

    const validRoles = ['admin', 'user', 'viewer']
    if (!validRoles.includes(role)) {
      return res.status(400).json({ error: 'Invalid role' })
    }

    const result = await pgPool.query(
      'UPDATE nexus.users SET role = $1 WHERE id = $2 RETURNING *',
      [role, id]
    )

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' })
    }

    res.json(result.rows[0])
  } catch (error) {
    res.status(500).json({ error: error.message })
  }
})

// ============================================================================
// MIDDLEWARE: AUTHENTICATION & AUTHORIZATION
// ============================================================================

const requireAuth = (req: any, res: any, next: any) => {
  const token = req.headers.authorization?.split(' ')[1]
  
  if (!token) {
    return res.status(401).json({ error: 'Unauthorized' })
  }

  // TODO: Verify JWT token
  // For now, assume authenticated
  req.user = { id: 1, role: 'admin' }
  next()
}

const requireAdmin = (req: any, res: any, next: any) => {
  requireAuth(req, res, () => {
    if (req.user?.role !== 'admin') {
      return res.status(403).json({ error: 'Admin access required' })
    }
    next()
  })
}
