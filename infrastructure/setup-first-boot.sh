#!/bin/bash

# Project Nexus - TUI Appliance Setup Script
# Auto-runs on first boot

set -e

echo "🚀 Project Nexus - First Boot Setup"
echo "════════════════════════════════════"

# Ensure directories exist
mkdir -p /opt/nexus/{backend,frontend}
mkdir -p /var/log/nexus
mkdir -p /etc/nexus

# Download latest Nexus code
echo "📥 Downloading Nexus code..."
cd /opt/nexus

# You would clone from your repo here
# git clone https://github.com/yourorg/nexus.git .

# Install backend dependencies
echo "📦 Installing backend dependencies..."
cd backend
npm ci --production
npm run build

# Install frontend dependencies  
echo "📦 Installing frontend dependencies..."
cd ../frontend
npm ci --production
npm run build

# Copy dist to nginx
cp -r dist /var/www/nexus

# Initialize database
echo "🗄️  Initializing database..."
cd /opt/nexus/backend
npm run migrate
npm run seed

# Create environment file
cat > /etc/nexus/backend.env << 'EOF'
NODE_ENV=production
PORT=3001
LOG_LEVEL=info
POSTGRES_URL=postgresql://nexus_user:nexus_password@localhost:5432/nexus_db
NEO4J_BOLT_URL=bolt://localhost:7687
NEO4J_USER=neo4j
NEO4J_PASSWORD=nexus_password
JWT_SECRET=change-me-to-long-random-secret-key
REDIS_HOST=localhost
REDIS_PORT=6379
EOF

# Set permissions
chown -R nexus:nexus /opt/nexus
chown -R nexus:nexus /var/log/nexus

# Start services
echo "🔄 Starting services..."
systemctl start postgresql
systemctl start neo4j
systemctl start redis
systemctl start nexus-backend
systemctl start nexus-graph-mirror
systemctl start nginx

# Wait for backend
echo "⏳ Waiting for backend to be ready..."
until curl -s http://localhost:3001/health > /dev/null 2>&1; do
  sleep 2
done

echo ""
echo "✅ Setup complete!"
echo ""
echo "🌐 Access Nexus:"
echo "   http://<vm-ip>"
echo ""
echo "📝 View logs:"
echo "   journalctl -u nexus-backend -f"
echo ""
