#!/bin/bash

# Project Nexus - Startup Script
# Initialize and start all services

set -e

echo "🚀 Starting Project Nexus..."

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check Node.js
echo -e "${BLUE}✓ Checking Node.js${NC}"
node --version

# Install dependencies
echo -e "${BLUE}✓ Installing backend dependencies${NC}"
cd backend
npm ci
npm run build
cd ..

echo -e "${BLUE}✓ Installing frontend dependencies${NC}"
cd frontend
npm ci
cd ..

# Check environment
echo -e "${BLUE}✓ Validating environment variables${NC}"
if [ -f backend/.env ]; then
  echo -e "${GREEN}✓ backend/.env exists${NC}"
else
  echo -e "${RED}✗ backend/.env missing! Copy from .env.development${NC}"
  cp backend/.env.development backend/.env
  echo -e "${GREEN}✓ Created backend/.env from .env.development${NC}"
fi

if [ -f frontend/.env ]; then
  echo -e "${GREEN}✓ frontend/.env exists${NC}"
else
  echo -e "${RED}✗ frontend/.env missing! Copy from .env.development${NC}"
  cp frontend/.env.development frontend/.env
  echo -e "${GREEN}✓ Created frontend/.env from .env.development${NC}"
fi

# Database migrations
echo -e "${BLUE}✓ Running database migrations${NC}"
cd backend
npm run migrate
cd ..

# Seed demo data (optional)
if [ "$1" = "--seed" ]; then
  echo -e "${BLUE}✓ Seeding demo data${NC}"
  cd backend
  npm run seed
  cd ..
fi

echo -e "${GREEN}✅ Setup complete!${NC}"
echo ""
echo "📝 To start services:"
echo ""
echo "Terminal 1 - Backend:"
echo "  cd backend && npm run dev"
echo ""
echo "Terminal 2 - Frontend:"
echo "  cd frontend && npm run dev"
echo ""
echo "Terminal 3 - Graph Mirror (optional):"
echo "  cd backend && npm run graph-mirror"
echo ""
echo "🌐 Frontend: http://localhost:5173"
echo "🔌 API: http://localhost:3001"
echo "📊 Neo4j Browser: http://localhost:7474"
echo ""
echo "Login with demo credentials:"
echo "  Username: demo"
echo "  Password: demo123"
