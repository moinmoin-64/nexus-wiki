#!/bin/bash
# Complete Wiki Verification and Startup Script
# Run this on the NixOS ISO to verify Project Nexus is working

set -e

echo "========================================="
echo "Project Nexus Wiki - Full Verification"
echo "========================================="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

SERVICES_GOOD=0
SERVICES_TOTAL=4

# Function to check service
check_service() {
    local service=$1
    echo -n "Checking $service... "
    
    if sudo systemctl is-active --quiet $service; then
        echo -e "${GREEN}✓ RUNNING${NC}"
        ((SERVICES_GOOD++))
    else
        echo -e "${RED}✗ INACTIVE${NC}"
        echo "  Starting $service..."
        sudo systemctl start $service
        sleep 2
        
        if sudo systemctl is-active --quiet $service; then
            echo -e "  ${GREEN}✓ Started successfully${NC}"
            ((SERVICES_GOOD++))
        else
            echo -e "  ${RED}✗ Failed to start${NC}"
        fi
    fi
}

echo "1. Verifying Services"
echo "===================="
check_service "postgresql"
check_service "redis"
check_service "neo4j"
check_service "nexus-backend"

echo ""
echo "Services Status: $SERVICES_GOOD/$SERVICES_TOTAL running"

if [ $SERVICES_GOOD -lt 4 ]; then
    echo -e "${RED}Warning: Not all services running. Waiting 10 seconds...${NC}"
    sleep 10
fi

echo ""
echo "2. Testing API Connectivity"
echo "==========================="

echo -n "Testing Backend API health... "
if timeout 5 curl -s http://localhost:3001/health > /dev/null 2>&1; then
    echo -e "${GREEN}✓ RESPONDING${NC}"
else
    echo -e "${YELLOW}⚠ Not responding yet (may still be starting)${NC}"
fi

echo ""
echo "3. Getting Network Information"
echo "=============================="

echo "Your network interfaces:"
ip addr show | grep -E "^\d+:|inet " | grep -B1 "inet"

echo ""
echo "To find your IP: look for 'inet' under 'ens18:' (e.g., 192.168.178.116)"
IP_ADDR=$(ip addr show ens18 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d/ -f1)

if [ -n "$IP_ADDR" ]; then
    echo -e "${GREEN}Your IP Address: $IP_ADDR${NC}"
else
    echo -e "${YELLOW}Could not automatically detect IP - run 'ip addr show' to find it${NC}"
fi

echo ""
echo "========================================="
echo "WIKI ACCESS INFORMATION"
echo "========================================="
echo ""

if [ -n "$IP_ADDR" ]; then
    echo "Open your browser and go to:"
    echo -e "${GREEN}http://$IP_ADDR:5173${NC}"
else
    echo "Open your browser and go to:"
    echo -e "${GREEN}http://<YOUR_IP>:5173${NC}"
    echo "(Replace <YOUR_IP> with your actual IP address)"
fi

echo ""
echo "Backend API (for developers):"
if [ -n "$IP_ADDR" ]; then
    echo -e "${GREEN}http://$IP_ADDR:3001${NC}"
else
    echo -e "${GREEN}http://<YOUR_IP>:3001${NC}"
fi

echo ""
echo "========================================="
echo "LOGIN CREDENTIALS"
echo "========================================="
echo ""
echo -e "${YELLOW}Demo Account:${NC}"
echo "  Username: demo"
echo "  Password: demo123"
echo ""
echo -e "${YELLOW}Admin Account:${NC}"
echo "  Username: admin"
echo "  Password: admin123"
echo ""

echo "========================================="
echo "To check service logs:"
echo "  sudo journalctl -u nexus-backend -n 30 -f"
echo ""
echo "To restart all services:"
echo "  sudo systemctl restart postgresql neo4j redis nexus-backend"
echo "========================================="
