# Project Nexus - Master Architecture Document

## Executive Summary

**Project Nexus** is a proprietary knowledge management system that combines the robustness of Wiki.js backend with a completely redesigned, modern frontend inspired by Notion and Obsidian. The system is architected for NixOS/Proxmox deployment, featuring a hybrid data layer (PostgreSQL + Neo4j), real-time collaboration, and interactive knowledge graph visualization.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    NEXUS ARCHITECTURE                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌──────────────┐  ┌──────────────┐      ┌──────────────┐       │
│  │   Browser    │  │   Editor     │      │    Graph     │       │
│  │  Vue.js 3    │  │   Tiptap     │      │ Cytoscape.js │       │
│  └──────────────┘  └──────────────┘      └──────────────┘       │
│         ▼                 ▼                       ▼               │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │          Nginx Reverse Proxy (SSL/TLS)                │    │
│  │    Let's Encrypt @ wiki-oliver.duckdns.org             │    │
│  └─────────────────────────────────────────────────────────┘    │
│         ▼                 ▼                       ▼               │
│  ┌──────────────┐  ┌──────────────┐      ┌──────────────┐       │
│  │  REST API    │  │  WebSocket   │      │  Graph API   │       │
│  │  :3001       │  │  Server      │      │  :7474       │       │
│  │  (Express.js)│  │  (Express-WS)│      │  (Neo4j)     │       │
│  └──────────────┘  └──────────────┘      └──────────────┘       │
│         ▼                 ▼                       ▼               │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │          Data Layer (Hybrid)                           │    │
│  ├─────────────────────────────────────────────────────────┤    │
│  │  PostgreSQL               │  Neo4j Read Replica         │    │
│  │  ├─ Documents            │  ├─ Document Nodes          │    │
│  │  ├─ Links                │  ├─ Relationships           │    │
│  │  ├─ Users                │  ├─ Centrality Scores       │    │
│  │  ├─ Activity Log          │  └─ Graph Queries          │    │
│  │  └─ Tags                  │                             │    │
│  └─────────────────────────────────────────────────────────┘    │
│         ▼                                                         │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  Backup Service (12h cycle)                             │   │
│  │  ├─ PostgreSQL Dumps (encrypted)                        │   │
│  │  └─ Git History Push (GitHub)                           │   │
│  └──────────────────────────────────────────────────────────┘   │
│         ▼                                                         │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  DevOps / CI-CD                                         │   │
│  │  ├─ NixOS (configuration + flakes)                      │   │
│  │  ├─ GitHub Actions (ISO auto-build)                     │   │
│  │  ├─ Proxmox VM (QEMU/KVM)                              │   │
│  │  └─ Systemd Services                                    │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

---

## Technology Stack

### Infrastructure & DevOps
| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Hypervisor** | Proxmox (QEMU/KVM) | VM hosting |
| **OS** | NixOS 23.11 | Declarative Linux |
| **Config Mgmt** | Nix Flakes | Reproducible builds |
| **ISO Generation** | nixos-generators | Bootable images |
| **CI/CD** | GitHub Actions | Automated builds |
| **Reverse Proxy** | Nginx | SSL/TLS, load balancing |
| **SSL** | Let's Encrypt (ACME) | Free certificate signing |
| **Process Mgmt** | systemd | Service orchestration |

### Backend
| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Runtime** | Node.js 18 | JavaScript engine |
| **Framework** | Express.js 4 | REST API server |
| **WebSocket** | express-ws | Real-time collaboration |
| **Database (OLTP)** | PostgreSQL 15 | Documents, metadata, users |
| **Database (OLAP)** | Neo4j 5 | Knowledge graph |
| **Graph Mirror** | Python 3 | [[Wikilinks]] extraction |
| **ORM/Query** | pg (node-postgres) | PostgreSQL client |
| **Graph Client** | neo4j-driver | Neo4j connectivity |

### Frontend
| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Framework** | Vue.js 3 | Reactive UI library |
| **Build Tool** | Vite 5 | Fast bundler |
| **Language** | TypeScript | Type safety |
| **CSS** | Tailwind CSS 3 | Utility-first styling |
| **Components** | Radix UI | Headless UI primitives |
| **Editor** | Tiptap 2 | Rich text editor |
| **Graph** | Cytoscape.js | Graph visualization |
| **State** | Pinia | Vue state management |
| **Routing** | Vue Router 4 | Client-side routing |
| **HTTP** | Axios | API client |

---

## Data Model

### PostgreSQL Schema

#### `nexus.documents`
```sql
CREATE TABLE nexus.documents (
  id SERIAL PRIMARY KEY,
  uuid UUID UNIQUE NOT NULL,
  title VARCHAR(255) NOT NULL,
  content TEXT,                    -- HTML version
  markdown_raw TEXT NOT NULL,      -- Editor backup
  status VARCHAR(50) DEFAULT 'draft' CHECK (status IN ('draft', 'review', 'published')),
  tags TEXT[] DEFAULT ARRAY[]::TEXT[],
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  created_by INTEGER REFERENCES nexus.users(id),
  updated_by INTEGER REFERENCES nexus.users(id)
);

-- Full-text search indexes
CREATE INDEX idx_documents_title_ft ON nexus.documents USING gin(to_tsvector('english', title));
CREATE INDEX idx_documents_content_ft ON nexus.documents USING gin(to_tsvector('english', content));
CREATE INDEX idx_documents_tags ON nexus.documents USING gin(tags);
```

#### `nexus.document_links`
Represents [[Wikilinks]] between documents.
```sql
CREATE TABLE nexus.document_links (
  id SERIAL PRIMARY KEY,
  source_doc_id INTEGER REFERENCES nexus.documents(id) ON DELETE CASCADE,
  target_doc_id INTEGER REFERENCES nexus.documents(id) ON DELETE CASCADE,
  link_type VARCHAR(50) DEFAULT 'reference',
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_document_links_source ON nexus.document_links(source_doc_id);
CREATE INDEX idx_document_links_target ON nexus.document_links(target_doc_id);
```

#### `nexus.users`
```sql
CREATE TABLE nexus.users (
  id SERIAL PRIMARY KEY,
  uuid UUID UNIQUE NOT NULL DEFAULT gen_random_uuid(),
  username VARCHAR(100) UNIQUE NOT NULL,
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  role VARCHAR(50) DEFAULT 'user' CHECK (role IN ('admin', 'user', 'viewer')),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  last_login TIMESTAMP
);
```

#### `nexus.activity_log`
Git-backed audit trail.
```sql
CREATE TABLE nexus.activity_log (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES nexus.users(id),
  action VARCHAR(100) NOT NULL,  -- CREATE_DOCUMENT, CHANGE_STATUS, etc
  document_id INTEGER REFERENCES nexus.documents(id),
  old_status VARCHAR(50),
  new_status VARCHAR(50),
  timestamp TIMESTAMP DEFAULT NOW(),
  details JSONB,
  ip_address INET
);

CREATE INDEX idx_activity_log_timestamp ON nexus.activity_log(timestamp DESC);
CREATE INDEX idx_activity_log_action ON nexus.activity_log(action);
```

### Neo4j Graph Schema

#### `:Document` Node
```cypher
:Document {
  uuid: STRING (unique),
  title: STRING,
  status: STRING ('draft'|'review'|'published'),
  centrality: INTEGER,      -- Calculated link count
  inlink_count: INTEGER,    -- Incoming links
  outlink_count: INTEGER,   -- Outgoing links
  tags: [STRING],
  created_at: DATETIME,
  updated_at: DATETIME
}
```

#### `:LINKS_TO` Relationship
```cypher
(doc1:Document)-[:LINKS_TO]->(doc2:Document)
```
Represents a `[[Wikilink]]` reference from doc1 to doc2.

---

## API Reference (Express.js)

### Authentication
```
POST   /api/auth/login              # JWT token generation
POST   /api/auth/logout             # Invalidate token
POST   /api/auth/verify             # Verify current token
```

### Documents
```
GET    /api/documents               # List (paginated, filterable)
GET    /api/documents/:id           # Get single document
POST   /api/documents               # Create new document
PUT    /api/documents/:id           # Update document
DELETE /api/documents/:id           # Delete document
GET    /api/search?q=...            # Full-text search
```

### Knowledge Graph
```
GET    /api/graph/neighborhood/:id  # Local neighborhood (1-2 hops)
GET    /api/graph/backlinks/:title  # Reverse links
GET    /api/graph/centrality        # Hub documents
```

### Governance
```
GET    /api/audit/log               # Audit trail (admin only)
GET    /api/audit/log/:docId        # Document history
PUT    /api/documents/:id/status    # Change document status
GET    /api/documents/:id/workflow  # Available transitions
GET    /api/users                   # List users (admin only)
POST   /api/users                   # Create user (admin only)
PUT    /api/users/:id/role          # Change role (admin only)
```

### Real-Time Collaboration
```
WS     /ws/collaborate/:docId       # WebSocket for live editing
```

---

## Workflow & Governance

### Document Status Flow
```
           ┌─────────────────────────┐
           │       DRAFT             │
           │ (Only creator can edit) │
           └────────┬────────────────┘
                    │
                    ▼
           ┌─────────────────────────┐
           │       REVIEW            │
           │ (Awaiting approval)     │
           └────────┬────────────────┘
                    │
                    ▼
           ┌─────────────────────────┐
           │      PUBLISHED          │
           │ (Read-only for viewers) │
           └─────────────────────────┘
```

### User Roles & Permissions
| Permission | Admin | User | Viewer |
|-----------|-------|------|--------|
| View documents | ✅ | ✅ | ✅ (published only) |
| Create document | ✅ | ✅ | ❌ |
| Edit document | ✅ | ✅ (draft/review) | ❌ |
| Publish document | ✅ | ✅ | ❌ |
| Delete document | ✅ | ✅ (draft/review only) | ❌ |
| Manage users | ✅ | ❌ | ❌ |
| View audit log | ✅ | ✅ | ❌ |
| Manage permissions | ✅ | ❌ | ❌ |

### Audit Logging (Git-Backed)
Every action is logged to `nexus.activity_log` and committed to Git:

```bash
[CHANGE_STATUS] My Document
Status: draft → review
Document ID: 42
User ID: 1
Time: 2024-01-15T14:30:00Z

Details:
{
  "reason": "Ready for review"
}
```

---

## Deployment Architecture

### NixOS System Configuration

```nix
flake.nix
├── inputs
│   ├── nixpkgs (23.11)
│   ├── nixos-generators
│   └── flake-utils
└── outputs
    ├── nixosConfigurations.nexus
    ├── packages.isoImage (bootable)
    ├── packages.qcowImage (VM disk)
    └── devShells.default
```

### Post-Boot Configuration
1. **Initial Setup** (first-boot)
   - Generate SSH keys
   - Configure backup Git repository
   - Initialize PostgreSQL schema
   - Neo4j cluster initialization

2. **Systemd Services**
   - `postgresql.service` → Database
   - `neo4j.service` → Graph database
   - `wiki-js.service` → Backend (Port 3000)
   - `nexus-api.service` → Express API (Port 3001)
   - `nexus-graph-mirror.service` → Sync service
   - `nexus-backup.timer` → Backup scheduler (12h)
   - `nginx.service` → Reverse proxy

3. **SSL/TLS**
   - ACME Let's Encrypt auto-renewal
   - Domain: `wiki-oliver.duckdns.org`
   - Automatic certificate provisioning

---

## Security Model

### Layers of Defense
1. **Network Layer**
   - Firewall (only ports 22, 80, 443 open)
   - DuckDNS for dynamic DNS
   - HTTPS enforced

2. **Application Layer**
   - JWT token authentication
   - Permission-based access control
   - Input validation & sanitization

3. **Database Layer**
   - PostgreSQL SSL connections
   - Per-user database roles
   - Encrypted backups
   - Activity logging

4. **System Layer**
   - SSH key-only authentication (no passwords)
   - Systemd security isolation
   - Kernel hardening (sysctl parameters)
   - Audit logging (auditd)

---

## Performance Considerations

### Database Optimization
| Query Type | Index | Performance |
|-----------|-------|-------------|
| Full-text search | GIN on `content`, `title` | O(log n) |
| Tag search | GIN on `tags` array | O(1) |
| Backlink queries | B-tree on `document_links` | O(1) |
| Graph traversal | Neo4j caching | O(e) edges |

### Caching Strategy
- **Frontend**: Browser cache (SPA assets)
- **API**: Redis (TODO: implement)
- **Database**: PostgreSQL shared buffers (256MB)

### Scaling Considerations
- **Horizontal**: Nginx load balancing
- **Vertical**: Increase VM resources
- **Database**: PostgreSQL streaming replication
- **Graph**: Neo4j causal clustering

---

## Backup & Recovery

### Backup Schedule
- **Frequency**: Every 12 hours
- **Type**: Full PostgreSQL dump (compressed)
- **Encryption**: AES-256-CBC
- **Storage**: Private GitHub repository
- **Retention**: Last 30 days (automated cleanup)

### Restore Procedure
```bash
# Download backup from GitHub
git clone git@github.com:YOUR_USERNAME/nexus-backups.git
cd nexus-backups

# Decrypt and restore
openssl enc -aes-256-cbc -d \
  -in nexus_db_YYYYMMDD_HHMMSS.sql.gz.enc \
  -out backup.sql.gz \
  -K $(cat /etc/nexus/backup.key | xxd -p -c 256)

# Restore to PostgreSQL
gunzip -c backup.sql.gz | psql nexus_db
```

---

## Monitoring & Maintenance

### Health Checks
```bash
# API health
curl https://wiki-oliver.duckdns.org/health

# PostgreSQL
psql -h localhost -U nexus_user -d nexus_db -c "SELECT 1"

# Neo4j
curl -u neo4j:neo4j http://localhost:7474/browser
```

### Log Locations
- `journalctl -u wiki-js` → Backend logs
- `journalctl -u nexus-api` → API logs
- `/var/log/nginx/` → Web server logs
- `/var/log/postgresql/` → Database logs

---

## Development Workflow

### Local Development Setup
```bash
# Clone repository
git clone https://github.com/YOUR_ORG/nexus.git
cd nexus

# Start infrastructure (NixOS VM or Docker Compose)
nix develop

# Run services
npm run backend  # Parallel terminal 1
npm run graph-mirror  # Parallel terminal 2
npm run frontend  # Parallel terminal 3
```

### Build & Deploy
```bash
# Build ISO locally
cd infrastructure && nix build .#packages.x86_64-linux.isoImage

# Push to repository
git push origin main  # GitHub Actions auto-builds

# Deploy to Proxmox
# 1. Download ISO from GitHub release  
# 2. Upload to Proxmox
# 3. Create VM and boot ISO
# 4. Run initial config wizard
```

---

## Project Phases Summary

| Phase | Component | Status |
|-------|-----------|--------|
| **1** | NixOS Infrastructure | ✅ Complete |
| **2** | Backend API & Neo4j Bridge | ✅ Complete |
| **3** | Vue.js Frontend | ✅ Complete |
| **4** | Knowledge Graph Visualization | ✅ Complete (in KnowledgeGraph.vue) |
| **5** | Governance & Audit System | ✅ Complete |

---

## Next Steps & Roadmap

### Immediate (Post-Launch)
- [ ] Implement JWT authentication (backend)
- [ ] Add rate limiting (Express middleware)
- [ ] Set up monitoring (Prometheus/Grafana)
- [ ] Performance testing & optimization

### Short-term (Q2 2024)
- [ ] AI-powered search suggestions
- [ ] Collaborative document locking
- [ ] Document templates system
- [ ] Advanced graph analytics

### Long-term (Q3-Q4 2024)
- [ ] Mobile app (React Native)
- [ ] Federated multi-instance setup
- [ ] Machine learning insights
- [ ] Full-text search in graph

---

## Support & Documentation

- **Infrastructure README**: `/infrastructure/README.md`
- **Backend API Docs**: `/backend/README.md`
- **Frontend UI Docs**: `/frontend/README.md`
- **Neo4j Queries**: `/backend/scripts/neo4j-queries.cypher`
- **Governance Model**: `/backend/api/governance.ts`

---

## Contact & Attribution

**Project Lead**: Oliver  
**Repository**: https://github.com/YOUR_ORG/nexus  
**Deployment**: wiki-oliver.duckdns.org

---

**Last Updated**: 2024-01-15  
**Version**: 1.0.0  
**License**: Proprietary
