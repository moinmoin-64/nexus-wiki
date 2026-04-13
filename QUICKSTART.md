# Project Nexus - Quick Start Guide

## 🚀 Local Development Setup

### 1️⃣ Prerequisites
- Node.js 18+
- PostgreSQL 15
- Neo4j 5
- Redis (optional, falls back to in-memory)

### 2️⃣ Setup Environment

```bash
# Copy environment templates
./scripts/setup-env.sh

# Or manually
cp backend/.env.development backend/.env
cp frontend/.env.development frontend/.env
```

### 3️⃣ Install Dependencies

```bash
cd backend
npm ci
cd ../frontend
npm ci
```

### 4️⃣ Initialize Database

```bash
cd backend

# Run migrations
npm run migrate

# Seed demo data
npm run seed

# Verify
psql -U nexus_user -d nexus_db -c "SELECT COUNT(*) FROM nexus.users;"
```

### 5️⃣ Start Services

**Terminal 1 - Backend API:**
```bash
cd backend
npm run dev
# Runs on http://localhost:3001
```

**Terminal 2 - Frontend:**
```bash
cd frontend
npm run dev
# Runs on http://localhost:5173
```

**Terminal 3 - Graph Mirror (optional):**
```bash
cd backend
npm run graph-mirror
```

### 6️⃣ Access Application

- **Frontend**: http://localhost:5173
- **API**: http://localhost:3001
- **API Docs**: http://localhost:3001/health
- **Neo4j Browser**: http://localhost:7474

### 7️⃣ Login Credentials

**Demo User:**
- Username: `demo`
- Password: `demo123`

**Admin User:**
- Username: `admin`
- Password: `admin123`

---

## 🧪 Testing

### Run Unit Tests
```bash
cd backend
npm run test          # Run tests once
npm run test:watch   # Watch mode
npm run test:cov     # Coverage report
```

### Run TypeScript Check
```bash
npm run typecheck
```

### Lint Code
```bash
npm run lint
npm run format
```

---

## 📊 Database Management

### View Logs
```bash
# Backend
tail -f backend/logs/all.log
tail -f backend/logs/error.log

# PostgreSQL
journalctl -u postgresql.service -f

# Neo4j
journalctl -u neo4j.service -f
```

### Backup Database
```bash
cd backend
npm run migrate
# Manual backup
pg_dump -U nexus_user nexus_db > backup.sql
```

### Reset Database
```bash
# WARNING: Deletes all data!
cd backend
npm run migrate:rollback --force
npm run migrate
npm run seed
```

---

## 🔧 Troubleshooting

### Port Already in Use
```bash
# Kill process on port 3001
lsof -ti:3001 | xargs kill -9

# Kill process on port 5173
lsof -ti:5173 | xargs kill -9
```

### Database Connection Error
```bash
# Check PostgreSQL
psql -U postgres

# Check Neo4j
cypher-shell -u neo4j -p nexus_password "RETURN 1"

# Reset PostgreSQL
sudo systemctl restart postgresql
```

### Module Not Found
```bash
# Clean and reinstall
rm -rf node_modules package-lock.json
npm ci
```

### Clear Cache
```bash
# Vue
rm -rf frontend/.vite frontend/dist

# TypeScript
rm -rf backend/dist
```

---

## 📝 Environment Variables

### Backend (.env)
```
NODE_ENV=development
PORT=3001
LOG_LEVEL=debug
POSTGRES_URL=postgresql://nexus_user:nexus_password@localhost:5432/nexus_db
NEO4J_BOLT_URL=bolt://localhost:7687
JWT_SECRET=<your-secret>
```

### Frontend (.env)
```
VITE_API_URL=http://localhost:3001
VITE_WS_URL=ws://localhost:3001
```

---

## 🎯 Common Tasks

### Create Demo Document
```bash
curl -X POST http://localhost:3001/api/documents \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{
    "title": "My First Document",
    "content": "<p>Hello World</p>",
    "markdown_raw": "# Hello World",
    "status": "draft"
  }'
```

### Search Documents
```bash
curl "http://localhost:3001/api/search?q=hello"
```

### Get Graph Neighborhood
```bash
curl "http://localhost:3001/api/graph/neighborhood/doc-uuid?depth=2"
```

---

## 🚀 Production Deployment

See: [DEPLOYMENT_GUIDE_COMPLETE.md](../DEPLOYMENT_GUIDE_COMPLETE.md)

For NixOS deployment with Proxmox VM setup and Let's Encrypt SSL/TLS.

---

## 📞 Support

- **Logs**: Check `backend/logs/` directory
- **Issues**: Look for error codes in response
- **API Doc**: Each endpoint has JSDoc comments in `api/server.ts`

Happy coding! 🎉
