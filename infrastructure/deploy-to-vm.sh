#!/bin/bash
# Deploy Nexus Backend to VM
# Usage: ./deploy-to-vm.sh <vm-ip> <ssh-key>

set -e

VM_IP=${1:-"192.168.1.100"}
SSH_KEY=${2:-"~/.ssh/id_rsa"}
BACKEND_DIR="$(cd "$(dirname "$0")/.." && pwd)/backend"

echo "🚀 Deploying Nexus Backend to VM..."
echo "IP: $VM_IP"
echo "SSH Key: $SSH_KEY"
echo ""

# Build backend
echo "📦 Building backend (TypeScript)..."
cd "$BACKEND_DIR"
npm run build

# Copy to VM
echo "📤 Uploading to VM..."
ssh -i "$SSH_KEY" nexus@"$VM_IP" mkdir -p /tmp/nexus-deploy
scp -i "$SSH_KEY" -r "$BACKEND_DIR/dist" nexus@"$VM_IP":/tmp/nexus-deploy/
scp -i "$SSH_KEY" -r "$BACKEND_DIR/services" nexus@"$VM_IP":/tmp/nexus-deploy/
scp -i "$SSH_KEY" "$BACKEND_DIR/package.json" nexus@"$VM_IP":/tmp/nexus-deploy/
scp -i "$SSH_KEY" "$BACKEND_DIR/package-lock.json" nexus@"$VM_IP":/tmp/nexus-deploy/

# Deploy
echo "🔄 Installing and restarting..."
ssh -i "$SSH_KEY" nexus@"$VM_IP" << 'DEPLOY'
  set -e
  cd /tmp/nexus-deploy
  npm ci --production
  sudo mv dist /opt/nexus/backend/
  sudo mv services /opt/nexus/backend/
  sudo systemctl restart nexus-backend
  sleep 2
  echo "✅ Deployment complete!"
  curl http://localhost:3001/health
DEPLOY

echo ""
echo "✅ Backend deployed successfully!"
