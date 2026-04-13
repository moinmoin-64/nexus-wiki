# Project Nexus - Backend API & Services

## Overview

The backend consists of three main components:

1. **API Server** (`api/server.js`): Express.js REST API + WebSocket server
2. **Graph Mirror Service** (`services/graph-mirror.py`): Extracts wikilinks from PostgreSQL and mirrors to Neo4j
3. **Authentication & Authorization**: Wiki.js integration (JWT-based)

## Installation

```bash
# Install dependencies
npm install

# Create .env file
cp .env.example .env

# Update .env with your configuration
```

## Running Services

### Development

```bash
# API Server (with hot-reload)
npm run dev

# Graph Mirror Service (separate terminal)
npm run graph-mirror
```

### Production

```bash
# API Server
npm start

# Graph Mirror (via systemd)
systemctl start nexus-graph-mirror
systemctl enable nexus-graph-mirror
```

## Environment Variables

```bash
PORT=3001
NODE_ENV=production

# PostgreSQL
POSTGRES_URL=postgresql://nexus_user:password@localhost:5432/nexus_db

# Neo4j
NEO4J_BOLT_URL=bolt://localhost:7687
NEO4J_USER=neo4j
NEO4J_PASSWORD=neo4j

# Graph Mirror Sync Interval (seconds)
GRAPH_SYNC_INTERVAL=300
```

## API Endpoints

### Health Check

```
GET /health
```

**Response:**
```json
{
  "status": "healthy",
  "timestamp": "2024-01-15T10:30:00Z",
  "postgres": "connected",
  "neo4j": "connected"
}
```

### Documents API

#### List Documents

```
GET /api/documents?limit=50&offset=0&status=published&search=design
```

**Query Parameters:**
- `limit`: Number of results (max 100, default: 50)
- `offset`: Pagination offset (default: 0)
- `status`: Filter by status (draft|review|published)
- `tags`: Comma-separated tags filter
- `search`: Full-text search query

**Response:**
```json
{
  "data": [
    {
      "id": 1,
      "uuid": "550e8400-e29b-41d4-a716-446655440000",
      "title": "System Design",
      "status": "published",
      "tags": ["architecture", "design"],
      "created_at": "2024-01-15T10:00:00Z",
      "updated_at": "2024-01-15T14:30:00Z"
    }
  ],
  "total": 150,
  "limit": 50,
  "offset": 0
}
```

#### Get Single Document

```
GET /api/documents/:id
```

**Response:**
```json
{
  "id": 1,
  "uuid": "550e8400-e29b-41d4-a716-446655440000",
  "title": "System Design",
  "content": "<html>...</html>",
  "markdown_raw": "# System Design\n\n[[API Architecture]] and [[Database Schema]]",
  "status": "published",
  "tags": ["architecture"],
  "created_at": "2024-01-15T10:00:00Z",
  "updated_at": "2024-01-15T14:30:00Z",
  "backlinks": [
    {
      "id": 5,
      "uuid": "660e8400-e29b-41d4-a716-446655440001",
      "title": "Microservices Approach"
    }
  ]
}
```

#### Create Document

```
POST /api/documents
Content-Type: application/json

{
  "title": "New Document",
  "content": "<p>Content</p>",
  "markdown_raw": "# New Document\n\nContent here",
  "status": "draft",
  "tags": ["new", "draft"],
  "created_by": 1
}
```

#### Update Document

```
PUT /api/documents/:id
Content-Type: application/json

{
  "title": "Updated Title",
  "markdown_raw": "# Updated Title\n\n[[Related Doc]]",
  "status": "review",
  "updated_by": 1
}
```

Automatically extracts and creates `[[Wikilinks]]` relationships.

#### Delete Document

```
DELETE /api/documents/:id
```

### Full-Text Search

```
GET /api/search?q=architecture&type=published
```

**Query Parameters:**
- `q`: Search query (min 2 chars)
- `type`: Filter by status (all|draft|review|published)

**Response:**
```json
{
  "results": [
    {
      "id": 1,
      "uuid": "550e8400-e29b-41d4-a716-446655440000",
      "title": "System Architecture",
      "status": "published",
      "rank": 0.85
    }
  ]
}
```

### Knowledge Graph Endpoints

#### Get Document Neighborhood

```
GET /api/graph/neighborhood/:id?depth=2
```

Returns all documents connected to a document up to specified depth.

**Response:**
```json
{
  "center": {
    "uuid": "550e8400-e29b-41d4-a716-446655440000",
    "title": "API Design",
    "centrality": 15
  },
  "neighbors": [
    {
      "uuid": "660e8400-e29b-41d4-a716-446655440001",
      "title": "Database Schema",
      "centrality": 8,
      "inlinks": 5,
      "outlinks": 3
    }
  ],
  "links": [
    {
      "source": "550e8400-e29b-41d4-a716-446655440000",
      "target": "660e8400-e29b-41d4-a716-446655440001"
    }
  ]
}
```

#### Get Backlinks

```
GET /api/graph/backlinks/Database%20Schema
```

Find all documents that link TO the specified document.

**Response:**
```json
{
  "backlinks": [
    {
      "uuid": "550e8400-e29b-41d4-a716-446655440000",
      "title": "API Design",
      "updated_at": "2024-01-15T14:30:00Z"
    }
  ]
}
```

#### Get Hub Documents (Centrality)

```
GET /api/graph/centrality?limit=20
```

Get most connected/central documents in the knowledge graph.

**Response:**
```json
{
  "hubs": [
    {
      "title": "System Architecture",
      "uuid": "550e8400-e29b-41d4-a716-446655440000",
      "centrality": 45
    }
  ]
}
```

### Real-Time Collaboration (WebSocket)

```
ws://localhost:3001/ws/collaborate/:docId?userId=user123
```

**Message Types:**

**Edit Notification:**
```json
{
  "type": "edit",
  "content": "Updated content here",
  "cursor": { "line": 5, "column": 10 }
}
```

**Save Document:**
```json
{
  "type": "save",
  "content": "Final content"
}
```

**Incoming Remote Edit:**
```json
{
  "type": "remoteEdit",
  "userId": "user456",
  "content": "Other user's edit",
  "cursor": { "line": 3, "column": 5 }
}
```

**User List:**
```json
{
  "type": "userList",
  "users": [
    {
      "userId": "user123",
      "connectedAt": "2024-01-15T10:00:00Z"
    }
  ]
}
```

## Database Schema

### nexus.documents

| Column | Type | Description |
|--------|------|-------------|
| id | SERIAL | Primary key |
| uuid | UUID | Unique identifier for API |
| title | VARCHAR(255) | Document title |
| content | TEXT | HTML content |
| markdown_raw | TEXT | Raw Markdown (for editing) |
| status | VARCHAR(50) | draft\|review\|published |
| tags | TEXT[] | Array of tags |
| created_at | TIMESTAMP | Creation timestamp |
| updated_at | TIMESTAMP | Last update |
| created_by | INTEGER | User ID |
| updated_by | INTEGER | User ID |

### nexus.document_links

| Column | Type | Description |
|--------|------|-------------|
| id | SERIAL | Primary key |
| source_doc_id | INTEGER | Source document ID |
| target_doc_id | INTEGER | Target document ID |
| link_type | VARCHAR(50) | Type of link |
| created_at | TIMESTAMP | Creation timestamp |

## Neo4j Graph Schema

### Nodes

**Document Node:**
```cypher
MATCH (d:Document {uuid: "550e8400-e29b-41d4-a716-446655440000"})
RETURN d.title, d.status, d.centrality, d.inlink_count, d.outlink_count
```

Properties:
- `title`: Document title
- `uuid`: Unique identifier
- `status`: Document status
- `centrality`: Link-based centrality score
- `inlink_count`: Number of incoming links
- `outlink_count`: Number of outgoing links
- `created_at`: ISO timestamp
- `updated_at`: ISO timestamp
- `tags`: Array of tags

### Relationships

**LINKS_TO:**
Represents a wikilink from one document to another.

```cypher
MATCH (source:Document)-[:LINKS_TO]->(target:Document)
RETURN source.title, target.title
```

## Troubleshooting

### API won't start

```bash
# Check PostgreSQL connection
psql postgresql://nexus_user:@localhost:5432/nexus_db

# Check Neo4j connection
curl -u neo4j:neo4j bolt://localhost:7687

# Check port conflict
lsof -i :3001
```

### Graph Mirror not syncing

```bash
# Check logs
journalctl -u nexus-graph-mirror -f

# Manual sync
python3 services/graph-mirror.py
```

### WebSocket connection fails

```bash
# Check WebSocket server
curl -i -N -H "Connection: Upgrade" -H "Upgrade: websocket" http://localhost:3001/ws/test
```

## Performance Tips

1. **Indexing**: All full-text search columns are indexed with GIN
2. **Pagination**: Always use limit/offset for large result sets
3. **Graph Queries**: Use depth limiting to avoid expensive traversals
4. **Caching**: Consider implementing Redis for frequently accessed documents
5. **Batch Operations**: Use database transactions for bulk updates

## Security Considerations

- ✅ Input validation with Joi schemas (TODO: implement)
- ✅ CORS configured
- ✅ Helmet security headers
- ⚠️ TODO: Implement JWT authentication
- ⚠️ TODO: Rate limiting
- ⚠️ TODO: SQL injection prevention (currently using parameterized queries)
- ⚠️ TODO: Permission checks for document access
