# Project Nexus - Master README

<div align="center">

# ⬢ Nexus
## A Modern Knowledge Management System

**Notion-meets-Obsidian | Next-Gen Wiki | Powered by NixOS**

![Status](https://img.shields.io/badge/status-Production%20Ready-green)
![Version](https://img.shields.io/badge/version-1.0.0-blue)
![License](https://img.shields.io/badge/license-Proprietary-red)

</div>

---

## 👋 Welcome to Project Nexus

Project Nexus is a **proprietary, production-grade knowledge management system** that reimag ines document collaboration. Built on top of Wiki.js backend infrastructure, Nexus delivers:

- 🎨 **Completely redesigned UI** – Dark mode, minimalist design inspired by Notion & Obsidian
- 📝 **Block-based editor** – Rich text editing with Tiptap, Markdown support, real-time collaboration
- 🕸️ **Interactive knowledge graph** – Visualize document relationships with Cytoscape.js
- 🔄 **Real-time collaboration** – Multiple users editing simultaneously via WebSockets
- 🏗️ **Hybrid data architecture** – PostgreSQL + Neo4j for documents + graph queries
- 🔐 **Enterprise governance** – Role-based access, document workflows, audit logging
- 🚀 **Declarative infrastructure** – NixOS flakes for reproducible, automated deployment

---

## 📦 What's Included

```
nexus/
├── infrastructure/          # NixOS configuration + ISO generation
│   ├── flake.nix           # Nix flakes definition
│   ├── configuration.nix   # System configuration
│   └── services/           # PostgreSQL, Neo4j, Nginx, etc.
│
├── backend/                # Express.js API + Graph Mirror
│   ├── api/
│   │   ├── server.js       # REST API + WebSocket server
│   │   └── governance.ts   # Role-based access control
│   └── services/
│       └── graph-mirror.py # PostgreSQL → Neo4j sync
│
├── frontend/               # Vue.js 3 Composition API
│   ├── src/
│   │   ├── components/     # DocumentEditor, Sidebar, KnowledgeGraph
│   │   ├── stores/         # Pinia state management
│   │   └── utils/          # API client
│   └── vite.config.ts      # Vite bundler config
│
└── /docs/
    ├── PROJECT_NEXUS_ARCHITECTURE.md
    ├── DEPLOYMENT_GUIDE.md
    └── API.md
```

---

## 🚀 Quick Start

### Option A: Docker Compose (Development)
```bash
docker-compose up -d

# Access:
# Frontend: http://localhost:5173
# API: http://localhost:3001
# PostgreSQL: localhost:5432
# Neo4j: http://localhost:7474
```

### Option B: Local Development
```bash
# Infrastructure (if using NixOS)
cd infrastructure
nix develop

# Backend
cd backend
npm install
npm run dev

# Frontend (new terminal)
cd frontend
npm install
npm run dev

# Graph Mirror (new terminal)
cd backend
npm run graph-mirror
```

### Option C: Production Deployment (Proxmox)
See **[DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md)** for full instructions.

```bash
# Build NixOS ISO
cd infrastructure
nix build .#packages.x86_64-linux.isoImage

# Upload to Proxmox and boot
# VM will auto-configure with all services
```

---

## 🏗️ Architecture

### System Design
```
┌─────────────────────────────────────────┐
│  Browser                                 │
│  (Vue.js 3 + Tailwind)                  │
└────────────────┬────────────────────────┘
                 │
        ┌────────▼─────────┐
        │ Nginx Reverse     │
        │ Proxy + SSL       │
        └────────┬──────────┘
                 │
    ┌────────────┼────────────┐
    │            │            │
    ▼            ▼            ▼
 REST API   WebSocket      Neo4j
 :3001      Server         :7474
           (Real-time)     (Graph)
    │            │            │
    └────────────┼────────────┘
                 │
        ┌────────▼──────────┐
        │ PostgreSQL (OLTP)  │
        │ Neo4j (OLAP)       │
        │ (Graph Mirror)     │
        └───────────────────┘
```

### Tech Stack
| Layer | Tech | Purpose |
|-------|------|---------|
| **OS** | NixOS 23.11 | Declarative Linux |
| **Frontend** | Vue 3 + Tailwind | Modern UI |
| **Backend** | Express.js + Node.js | REST API |
| **Editor** | Tiptap 2 | Rich text editing |
| **Graph** | Neo4j + Cytoscape.js | Knowledge graph |
| **Database** | PostgreSQL 15 | Primary storage |
| **DevOps** | NixOS Flakes, GitHub Actions | CI/CD automation |
| **Infrastructure** | Proxmox QEMU/KVM | Virtualization |

---

## 🎯 Core Features

### 📄 Documents
- Create, edit, delete documents with rich text editor
- [[Wikilinks]] support for document references  
- Markdown + HTML storage
- Automatic tagging and categorization
- Full-text search with TF-IDF ranking

### 🕸️ Knowledge Graph
- Interactive 2D graph visualization
- Dynamic node sizing based on centrality
- Local neighborhood exploration
- Hub detection (most central documents)
- Backlink discovery
- Graph queries (distance, clustering, etc.)

### 🔄 Real-Time Collaboration
- Multiple users editing same document
- Live cursor positions
- Conflict-free updates (CRDT-like)
- Change broadcasting via WebSocket
- Activity log

### 🔐 Governance
- Role-based access control (Admin/User/Viewer)
- Document status workflow (Draft → Review → Published)
- Audit logging with Git backing
- Permission matrix
- Activity tracking

---

## 📚 Documentation

### Architecture & Design
- **[PROJECT_NEXUS_ARCHITECTURE.md](./PROJECT_NEXUS_ARCHITECTURE.md)** – Complete system architecture
- **[Backend README](./backend/README.md)** – API reference & Graph queries
- **[Frontend README](./frontend/README.md)** – Component structure & UI guide
- **[Infrastructure README](./infrastructure/README.md)** – NixOS setup & hardening

### Deployment & Operations
- **[DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md)** – Step-by-step production setup
- **[Neo4j Queries](./backend/scripts/neo4j-queries.cypher)** – Graph query examples
- **Governance Model** – [governance.ts](./backend/api/governance.ts)

---

## 🔒 Security Features

✅ **Hardened NixOS** – Kernel hardening, minimal attack surface  
✅ **SSL/TLS** – Let's Encrypt automatic certificate renewal  
✅ **Role-based access** – Admin/User/Viewer permissions  
✅ **Audit logging** – Every action tracked in activity_log  
✅ **Encrypted backups** – AES-256 backup encryption  
✅ **Git audit trail** – Changes committed to GitHub history  
✅ **SSH key auth** – No password-based login  
✅ **Database SSL** – PostgreSQL connections encrypted  

---

## 🚀 Deployment Options

### 1. **Development** (Laptop/Desktop)
```bash
docker-compose up -d
# Or run locally with npm + nix
```

### 2. **Production** (Proxmox VM)
- NixOS ISO boot from Proxmox
- Automated systemd services
- SSL/TLS via Let's Encrypt
- 12-hour encrypted backups to GitHub
- Full audit logging

### 3. **Enterprise** (Multiple VMs)
- Load-balanced Nginx
- PostgreSQL streaming replication
- Neo4j causal clustering
- External monitoring (Prometheus)

---

## 📖 API Examples

### Create Document
```bash
POST /api/documents
Content-Type: application/json

{
  "title": "System Design",
  "markdown_raw": "# System Design\n\n[[API Architecture]] and [[Database Schema]]",
  "status": "draft",
  "tags": ["architecture", "design"]
}
```

### Search Documents
```bash
GET /api/search?q=architecture&type=published
```

### Get Knowledge Graph
```bash
GET /api/graph/neighborhood/:docId?depth=2
```

### Real-Time Collaboration
```javascript
const ws = new WebSocket('ws://localhost:3001/ws/collaborate/doc-uuid?userId=user123');

ws.onmessage = (event) => {
  const { type, content, userId } = JSON.parse(event.data);
  if (type === 'remoteEdit') {
    // Apply remote edit to local editor
  }
};
```

---

## 🛠️ Development Workflow

### Setup Local Environment
```bash
# Clone repository
git clone https://github.com/YOUR_ORG/nexus.git
cd nexus

# Install dependencies
nix flake update  # or just use npm/python directly

# Start services
npm run dev:backend   # Terminal 1
npm run dev:frontend  # Terminal 2
python3 services/graph-mirror.py  # Terminal 3
```

### Code Structure
- **Backend**: TypeScript/JavaScript (Express.js)
- **Frontend**: Vue 3 with TypeScript
- **Infrastructure**: Nix + systemd services
- **Database**: SQL (PostgreSQL) + Cypher (Neo4j)

### Making Changes
1. Create feature branch
2. Make changes
3. Test locally
4. Commit with conventional commits
5. Push to GitHub
6. GitHub Actions auto-builds NixOS ISO
7. Deploy ISO to Proxmox

---

## 📊 Database Schema

### Core Tables
```sql
-- Documents
nexus.documents (id, uuid, title, markdown_raw, status, created_at, tags, ...)

-- Links (Wikilinks)
nexus.document_links (source_doc_id, target_doc_id, link_type, created_at, ...)

-- Users
nexus.users (id, uuid, username, email, role, created_at, last_login, ...)

-- Activity Log
nexus.activity_log (id, user_id, action, document_id, old_status, new_status, ...)
```

### Neo4j Schema
```cypher
:Document {
  uuid, title, status,
  centrality, inlink_count, outlink_count,
  tags, created_at, updated_at
}

:LINKS_TO  // Relationship between documents
```

---

## 🔍 Search Capabilities

### Full-Text Search
```bash
GET /api/search?q=architecture
```

### Advanced Queries
```bash
# By status
GET /api/search?q=design&type=published

# By tags
GET /api/documents?tags=architecture,design

# Backlinks
GET /api/graph/backlinks/System%20Design
```

---

## 🎨 UI Features

### Dark Mode (Default)
-  Professional dark theme with Tailwind CSS
- Customizable color scheme
- Light mode available (toggle)

### Editor
- Block-based (Tiptap)
- Slash commands (`/`)
- Markdown support
- Media drag-and-drop
- Real-time collaboration cursors

### Graph Visualization
- Interactive Cytoscape.js
- Dynamic layout (cola algorithm)
- Color-coded nodes
- Zoom & pan
- Neighborhood focus

---

## 💾 Backup & Recovery

### Automatic Backups
- **Frequency**: Every 12 hours
- **Type**: Full PostgreSQL dump (compressed + encrypted)
- **Storage**: GitHub private repository
- **Retention**: Last 30 backup cycles

### Manual Restore
```bash
git clone git@github.com:YOUR_USERNAME/nexus-backups.git
cd nexus-backups
openssl enc -aes-256-cbc -d -in backup.sql.gz.enc | gunzip | psql nexus_db
```

---

## 📈 Performance

### Database Optimization
- Full-text search indexes (GIN)
- Tag filtering (Array indexes)
- Document link indexes
- Neo4j query caching

### Scaling
- Horizontal: Nginx load balancing
- Vertical: VM resource allocation
- Database: PostgreSQL replication
- Graph: Neo4j clustering

---

## 🤝 Contributing

1. **Fork** the repository
2. **Create** feature branch (`git checkout -b feature/amazing-feature`)
3. **Make** changes following code style
4. **Test** locally
5. **Commit** with conventional messages
6. **Push** to GitHub
7. **Create** Pull Request

---

## 📝 License

**Proprietary** – Project Nexus. All rights reserved.

---

## 🆘 Support & Issues

- **Bug Reports**: GitHub Issues
- **Documentation**: See [docs/](./docs/) folder
- **API Questions**: See [backend/README.md](./backend/README.md)
- **Deployment Help**: See [DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md)

---

## 🎉 Acknowledgments

- **Wiki.js** – Backend foundation
- **Vue.js** – Frontend framework
- **Tiptap** – Rich text editor
- **NixOS** – Declarative Linux
- **Neo4j** – Graph database

---

<div align="center">

### 🚀 Ready to launch Nexus?

[⬇️ Get Started](./DEPLOYMENT_GUIDE.md) | [📖 Read Docs](./PROJECT_NEXUS_ARCHITECTURE.md) | [💬 Get Support](#support--issues)

**Made with ❤️ by Oliver**

</div>
