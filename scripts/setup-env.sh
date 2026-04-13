#!/bin/bash

# Project Nexus - Environment Setup Script
# Generates required .env files from templates

set -e

echo "🔧 Setting up environment variables..."

# Function to generate a random secret
generate_secret() {
  openssl rand -base64 32 2>/dev/null || head -c 32 /dev/urandom | base64
}

# Backend .env
if [ ! -f backend/.env ]; then
  echo "📝 Creating backend/.env from template..."
  
  JWT_SECRET=$(generate_secret)
  
  cat > backend/.env << EOF
# Application
NODE_ENV=development
PORT=3001
LOG_LEVEL=debug

# Database - PostgreSQL
POSTGRES_URL=postgresql://nexus_user:nexus_password@localhost:5432/nexus_db

# Graph Database - Neo4j
NEO4J_BOLT_URL=bolt://localhost:7687
NEO4J_USER=neo4j
NEO4J_PASSWORD=nexus_password

# Authentication
JWT_SECRET=$JWT_SECRET
JWT_EXPIRY=7d
REFRESH_TOKEN_EXPIRY=30d

# Redis (optional)
REDIS_HOST=localhost
REDIS_PORT=6379

# CORS
CORS_ORIGIN=http://localhost:5173
EOF

  echo "✅ Created backend/.env"
else
  echo "⏭️  backend/.env already exists"
fi

# Frontend .env
if [ ! -f frontend/.env ]; then
  echo "📝 Creating frontend/.env from template..."
  
  cat > frontend/.env << EOF
# Frontend Environment Variables

VITE_API_URL=http://localhost:3001
VITE_WS_URL=ws://localhost:3001
VITE_ENVIRONMENT=development
EOF

  echo "✅ Created frontend/.env"
else
  echo "⏭️  frontend/.env already exists"
fi

echo ""
echo "✨ Environment setup complete!"
echo ""
echo "📌 Important:"
echo "  - Change JWT_SECRET in production to a strong random value"
echo "  - Update database credentials if not using defaults"
echo "  - Configure Neo4j password"
echo ""
