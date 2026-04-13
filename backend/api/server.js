/**
 * Project Nexus - Backend API Server
 * Express.js REST API + WebSocket Server
 * Bridge between Wiki.js, PostgreSQL, and Neo4j
 */

require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const { Pool } = require('pg');
const neo4j = require('neo4j-driver');
const { v4: uuidv4 } = require('uuid');
const expressWs = require('express-ws');

// Configuration
const PORT = process.env.PORT || 3001;
const NODE_ENV = process.env.NODE_ENV || 'production';

// Database Connections
const pgPool = new Pool({
  connectionString: process.env.POSTGRES_URL || 'postgresql://nexus_user:@localhost:5432/nexus_db',
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});

const neo4jDriver = neo4j.driver(
  process.env.NEO4J_BOLT_URL || 'bolt://localhost:7687',
  neo4j.auth.basic(
    process.env.NEO4J_USER || 'neo4j',
    process.env.NEO4J_PASSWORD || 'neo4j'
  )
);

// Express Setup
const app = express();
expressWs(app);

// Middleware
app.use(helmet());
app.use(cors());
app.use(morgan('combined'));
app.use(express.json({ limit: '50mb' }));

// Health Check
app.get('/health', async (req, res) => {
  try {
    const pgResult = await pgPool.query('SELECT NOW()');
    const neo4jSession = neo4jDriver.session();
    await neo4jSession.run('RETURN 1');
    neo4jSession.close();
    
    res.json({
      status: 'healthy',
      timestamp: new Date().toISOString(),
      postgres: 'connected',
      neo4j: 'connected'
    });
  } catch (error) {
    res.status(503).json({
      status: 'unhealthy',
      error: error.message
    });
  }
});

// ============================================================================
// DOCUMENT ENDPOINTS
// ============================================================================

/**
 * GET /api/documents
 * Fetch all documents with pagination & filtering
 */
app.get('/api/documents', async (req, res) => {
  try {
    const { limit = 50, offset = 0, status, tags, search } = req.query;
    const queryLimit = Math.min(parseInt(limit), 100);
    const queryOffset = parseInt(offset);
    
    let query = 'SELECT id, uuid, title, status, tags, created_at, updated_at FROM nexus.documents WHERE 1=1';
    const params = [];
    let paramCount = 1;
    
    if (status) {
      query += ` AND status = $${paramCount}`;
      params.push(status);
      paramCount++;
    }
    
    if (tags) {
      const tagArray = tags.split(',');
      query += ` AND tags && $${paramCount}::text[]`;
      params.push(tagArray);
      paramCount++;
    }
    
    if (search) {
      query += ` AND (to_tsvector('english', title) @@ plainto_tsquery('english', $${paramCount}) 
                  OR to_tsvector('english', content) @@ plainto_tsquery('english', $${paramCount}))`;
      params.push(search);
      paramCount++;
    }
    
    query += ` ORDER BY updated_at DESC LIMIT $${paramCount} OFFSET $${paramCount + 1}`;
    params.push(queryLimit, queryOffset);
    
    const result = await pgPool.query(query, params);
    
    // Get total count
    let countQuery = 'SELECT COUNT(*) as total FROM nexus.documents WHERE 1=1';
    const countParams = [];
    let countParamCount = 1;
    
    if (status) {
      countQuery += ` AND status = $${countParamCount}`;
      countParams.push(status);
      countParamCount++;
    }
    
    const countResult = await pgPool.query(countQuery, countParams);
    
    res.json({
      data: result.rows,
      total: parseInt(countResult.rows[0].total),
      limit: queryLimit,
      offset: queryOffset
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

/**
 * GET /api/documents/:id
 * Fetch single document with full content
 */
app.get('/api/documents/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    const result = await pgPool.query(
      'SELECT * FROM nexus.documents WHERE uuid = $1 OR id = $1',
      [id]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Document not found' });
    }
    
    const doc = result.rows[0];
    
    // Get backlinks
    const backlinksResult = await pgPool.query(`
      SELECT d.id, d.uuid, d.title
      FROM nexus.documents d
      JOIN nexus.document_links dl ON d.id = dl.source_doc_id
      WHERE dl.target_doc_id = $1
    `, [doc.id]);
    
    res.json({
      ...doc,
      backlinks: backlinksResult.rows
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

/**
 * POST /api/documents
 * Create new document
 */
app.post('/api/documents', async (req, res) => {
  try {
    const { title, content, markdown_raw, status = 'draft', tags = [], created_by } = req.body;
    const uuid = uuidv4();
    const now = new Date();
    
    const result = await pgPool.query(
      `INSERT INTO nexus.documents (uuid, title, content, markdown_raw, status, tags, created_at, updated_at, created_by)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
       RETURNING *`,
      [uuid, title, content, markdown_raw, status, tags, now, now, created_by]
    );
    
    res.status(201).json(result.rows[0]);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

/**
 * PUT /api/documents/:id
 * Update document
 */
app.put('/api/documents/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { title, content, markdown_raw, status, tags, updated_by } = req.body;
    const now = new Date();
    
    // Fetch current document to extract wikilinks
    const currentDoc = await pgPool.query(
      'SELECT id FROM nexus.documents WHERE uuid = $1 OR id = $1',
      [id]
    );
    
    if (currentDoc.rows.length === 0) {
      return res.status(404).json({ error: 'Document not found' });
    }
    
    const docId = currentDoc.rows[0].id;
    
    // Update document
    const result = await pgPool.query(
      `UPDATE nexus.documents 
       SET title = COALESCE($1, title),
           content = COALESCE($2, content),
           markdown_raw = COALESCE($3, markdown_raw),
           status = COALESCE($4, status),
           tags = COALESCE($5, tags),
           updated_at = $6,
           updated_by = $7
       WHERE id = $8
       RETURNING *`,
      [title, content, markdown_raw, status, tags, now, updated_by, docId]
    );
    
    // Extract wikilinks and create document_links
    const wiklinkRegex = /\[\[([^\]]+)\]\]/g;
    let match;
    const wikilinks = [];
    
    while ((match = wiklinkRegex.exec(markdown_raw || '')) !== null) {
      wikilinks.push(match[1]);
    }
    
    // Clear existing links
    await pgPool.query('DELETE FROM nexus.document_links WHERE source_doc_id = $1', [docId]);
    
    // Insert new links
    for (const wikilink of wikilinks) {
      const targetDoc = await pgPool.query(
        'SELECT id FROM nexus.documents WHERE title ILIKE $1 LIMIT 1',
        [wikilink]
      );
      
      if (targetDoc.rows.length > 0) {
        await pgPool.query(
          'INSERT INTO nexus.document_links (source_doc_id, target_doc_id) VALUES ($1, $2)',
          [docId, targetDoc.rows[0].id]
        );
      }
    }
    
    res.json(result.rows[0]);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

/**
 * DELETE /api/documents/:id
 */
app.delete('/api/documents/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    const result = await pgPool.query(
      'DELETE FROM nexus.documents WHERE uuid = $1 OR id = $1 RETURNING id',
      [id]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Document not found' });
    }
    
    res.json({ success: true, id: result.rows[0].id });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ============================================================================
// GRAPH & NAVIGATION ENDPOINTS
// ============================================================================

/**
 * GET /api/graph/neighborhood/:id
 * Get knowledge graph local neighborhood
 */
app.get('/api/graph/neighborhood/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { depth = 1 } = req.query;
    const neo4jSession = neo4jDriver.session();
    
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
      { uuid: id, depth: parseInt(depth) }
    );
    
    neo4jSession.close();
    
    if (result.records.length === 0) {
      return res.status(404).json({ error: 'Document not found in graph' });
    }
    
    res.json(result.records[0].get(0));
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

/**
 * GET /api/graph/backlinks/:title
 * Find all documents linking to a document
 */
app.get('/api/graph/backlinks/:title', async (req, res) => {
  try {
    const { title } = req.params;
    const neo4jSession = neo4jDriver.session();
    
    const result = await neo4jSession.run(
      `MATCH (source:Document)-[:LINKS_TO]->(target:Document {title: $title})
       RETURN {
         uuid: source.uuid,
         title: source.title,
         updated_at: source.updated_at
       } as source
       ORDER BY source.updated_at DESC`,
      { title: decodeURIComponent(title) }
    );
    
    neo4jSession.close();
    
    const backlinks = result.records.map(record => record.get('source'));
    res.json({ backlinks });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

/**
 * GET /api/graph/centrality
 * Get hub documents (highest centrality)
 */
app.get('/api/graph/centrality', async (req, res) => {
  try {
    const { limit = 20 } = req.query;
    const neo4jSession = neo4jDriver.session();
    
    const result = await neo4jSession.run(
      `MATCH (d:Document)
       RETURN d.title as title, d.uuid as uuid, d.centrality as centrality
       ORDER BY centrality DESC
       LIMIT $limit`,
      { limit: parseInt(limit) }
    );
    
    neo4jSession.close();
    
    const hubs = result.records.map(record => ({
      title: record.get('title'),
      uuid: record.get('uuid'),
      centrality: record.get('centrality')
    }));
    
    res.json({ hubs });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ============================================================================
// SEARCH ENDPOINTS
// ============================================================================

/**
 * GET /api/search
 * Full-text search
 */
app.get('/api/search', async (req, res) => {
  try {
    const { q, type = 'all' } = req.query;
    
    if (!q || q.length < 2) {
      return res.status(400).json({ error: 'Search query too short' });
    }
    
    let query = `
      SELECT id, uuid, title, status, 
             ts_rank(to_tsvector('english', title || ' ' || COALESCE(content, '')), 
                     plainto_tsquery('english', $1)) as rank
      FROM nexus.documents
      WHERE (to_tsvector('english', title) @@ plainto_tsquery('english', $1)
             OR to_tsvector('english', content) @@ plainto_tsquery('english', $1))
    `;
    
    const params = [q];
    let paramCount = 2;
    
    if (type !== 'all') {
      query += ` AND status = $${paramCount}`;
      params.push(type);
    }
    
    query += ` ORDER BY rank DESC LIMIT 50`;
    
    const result = await pgPool.query(query, params);
    res.json({ results: result.rows });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ============================================================================
// WEBSOCKET: REAL-TIME COLLABORATION
// ============================================================================

const activeConnections = new Map();

app.ws('/ws/collaborate/:docId', (ws, req) => {
  const { docId } = req.params;
  const userId = req.query.userId || 'anonymous';
  
  // Add to active connections
  if (!activeConnections.has(docId)) {
    activeConnections.set(docId, new Set());
  }
  activeConnections.get(docId).add({
    ws,
    userId,
    connectedAt: new Date()
  });
  
  console.log(`User ${userId} connected to document ${docId}`);
  
  // Broadcast user list
  const broadcastUserList = () => {
    const users = Array.from(activeConnections.get(docId) || [])
      .map(conn => ({
        userId: conn.userId,
        connectedAt: conn.connectedAt
      }));
    
    activeConnections.get(docId)?.forEach(conn => {
      if (conn.ws.readyState === 1) {
        conn.ws.send(JSON.stringify({ type: 'userList', users }));
      }
    });
  };
  
  broadcastUserList();
  
  // Handle incoming messages
  ws.on('message', async (message) => {
    try {
      const data = JSON.parse(message);
      
      switch (data.type) {
        case 'edit':
          // Broadcast edit to other users
          activeConnections.get(docId)?.forEach(conn => {
            if (conn.ws !== ws && conn.ws.readyState === 1) {
              conn.ws.send(JSON.stringify({
                type: 'remoteEdit',
                userId,
                content: data.content,
                cursor: data.cursor
              }));
            }
          });
          break;
          
        case 'save':
          // Save to database
          // This will be handled by PUT /api/documents/:id
          break;
      }
    } catch (error) {
      console.error('WebSocket error:', error);
    }
  });
  
  // Handle disconnect
  ws.on('close', () => {
    const connections = activeConnections.get(docId);
    if (connections) {
      connections.forEach(conn => {
        if (conn.ws === ws) {
          connections.delete(conn);
        }
      });
    }
    console.log(`User ${userId} disconnected from document ${docId}`);
    broadcastUserList();
  });
});

// ============================================================================
// ERROR HANDLING & STARTUP
// ============================================================================

app.use((err, req, res, next) => {
  console.error(err);
  res.status(500).json({ error: 'Internal Server Error' });
});

app.listen(PORT, () => {
  console.log(`🚀 Nexus API Server running on port ${PORT}`);
  console.log(`📊 Environment: ${NODE_ENV}`);
});

// Graceful shutdown
process.on('SIGINT', async () => {
  console.log('\nShutting down gracefully...');
  await pgPool.end();
  await neo4jDriver.close();
  process.exit(0);
});

module.exports = app;
