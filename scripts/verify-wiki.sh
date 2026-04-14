#!/bin/bash
# Verify Project Nexus Wiki is accessible

echo "========================================="
echo "Project Nexus Wiki Verification Script"
echo "========================================="
echo ""

# Check PostgreSQL
echo "1. Checking PostgreSQL..."
sudo systemctl status postgresql > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✓ PostgreSQL is running"
else
    echo "✗ PostgreSQL not running - starting..."
    sudo systemctl start postgresql
    sleep 3
fi

# Check Redis
echo "2. Checking Redis..."
sudo systemctl status redis > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✓ Redis is running"
else
    echo "✗ Redis not running - starting..."
    sudo systemctl start redis
    sleep 3
fi

# Check Neo4j
echo "3. Checking Neo4j..."
sudo systemctl status neo4j > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✓ Neo4j is running"
else
    echo "✗ Neo4j not running - starting..."
    sudo systemctl start neo4j
    sleep 5
fi

# Check Backend
echo "4. Checking Nexus Backend..."
sudo systemctl status nexus-backend > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✓ Nexus Backend is running"
else
    echo "✗ Backend not running - starting..."
    sudo systemctl start nexus-backend
    sleep 3
fi

echo ""
echo "5. Testing Backend API health..."
HEALTH_CHECK=$(curl -s http://localhost:3001/health || echo "FAILED")
if [ "$HEALTH_CHECK" != "FAILED" ]; then
    echo "✓ Backend API is responding"
else
    echo "✗ Backend API not responding yet - it may still be starting"
fi

echo ""
echo "========================================="
echo "Wiki Access Information:"
echo "========================================="
echo ""
echo "Get your IP address with: ip addr show"
echo ""
echo "Access URLs (replace IP with your actual IP):"
echo "  Frontend:  http://<YOUR_IP>:5173"
echo "  Backend:   http://<YOUR_IP>:3001"
echo ""
echo "Login Credentials:"
echo "  Demo User:"
echo "    Username: demo"
echo "    Password: demo123"
echo ""
echo "  Admin User:"
echo "    Username: admin"
echo "    Password: admin123"
echo ""
echo "========================================="
