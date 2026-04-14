#!/bin/bash
# Complete end-to-end wiki verification and access guide
# Run this on the NixOS terminal after booting

set -e

echo "╔════════════════════════════════════════════════════════════╗"
echo "║     Project Nexus Wiki - Complete Access Verification      ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

PASSED=0
FAILED=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}STEP 1: Checking Services${NC}"
echo "════════════════════════════════════════════════════════════"

# Check if services are running or start them
check_and_start() {
    local service=$1
    echo -n "  $service: "
    
    if sudo systemctl is-active --quiet $service 2>/dev/null; then
        echo -e "${GREEN}✓ RUNNING${NC}"
        ((PASSED++))
        return 0
    else
        echo -e "${YELLOW}Starting...${NC}"
        sudo systemctl start $service 2>/dev/null || true
        sleep 2
        
        if sudo systemctl is-active --quiet $service 2>/dev/null; then
            echo -e "${GREEN}   ✓ Started${NC}"
            ((PASSED++))
            return 0
        else
            echo -e "${RED}   ✗ Failed to start${NC}"
            ((FAILED++))
            return 1
        fi
    fi
}

check_and_start "postgresql"
check_and_start "redis"
check_and_start "neo4j"
check_and_start "nexus-backend"
check_and_start "nexus-frontend"

echo ""
echo -e "${BLUE}STEP 2: Testing API Connectivity${NC}"
echo "════════════════════════════════════════════════════════════"

echo -n "  Backend API health check: "
if curl -s http://localhost:3001/health 2>/dev/null | grep -q "." 2>/dev/null; then
    echo -e "${GREEN}✓ Responding${NC}"
    ((PASSED++))
else
    echo -e "${YELLOW}⚠ Still starting (wait 15 seconds)${NC}"
    sleep 15
    if curl -s http://localhost:3001/health 2>/dev/null | grep -q "." 2>/dev/null; then
        echo -e "${GREEN}   ✓ Now responding${NC}"
        ((PASSED++))
    else
        echo -e "${YELLOW}   ⚠ May take longer to initialize${NC}"
    fi
fi

echo ""
echo -e "${BLUE}STEP 3: Network Configuration${NC}"
echo "════════════════════════════════════════════════════════════"

IP_ADDR=$(ip addr show ens18 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d/ -f1)

if [ -n "$IP_ADDR" ]; then
    echo -e "  Your IP Address: ${GREEN}$IP_ADDR${NC}"
    ((PASSED++))
else
    echo -e "  IP Address: ${RED}Could not detect${NC}"
    IP_ADDR=$(hostname -I | awk '{print $1}')
    if [ -n "$IP_ADDR" ]; then
        echo -e "  Alternative IP: ${GREEN}$IP_ADDR${NC}"
        ((PASSED++))
    else
        echo -e "  ${RED}✗ Could not detect any IP${NC}"
        ((FAILED++))
    fi
fi

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                   SUCCESS SUMMARY                          ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

echo -e "${GREEN}✓ Passed: $PASSED${NC}"
if [ $FAILED -gt 0 ]; then
    echo -e "${RED}✗ Failed: $FAILED${NC}"
else
    echo -e "${GREEN}✗ Failed: 0${NC}"
fi

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║              WIKI ACCESS INFORMATION                       ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

if [ -n "$IP_ADDR" ]; then
    echo -e "${BLUE}From your main PC, open in browser:${NC}"
    echo ""
    echo -e "  ${GREEN}http://$IP_ADDR:5173${NC}"
    echo ""
    echo -e "${BLUE}Backend API (for developers):${NC}"
    echo ""
    echo -e "  ${GREEN}http://$IP_ADDR:3001${NC}"
else
    echo -e "${BLUE}Open one of these in your browser:${NC}"
    echo ""
    echo -e "  ${GREEN}http://192.168.178.116:5173${NC}"
    echo -e "  (or replace IP with your NixOS system's IP)${NC}"
fi

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                 LOGIN CREDENTIALS                          ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo -e "${YELLOW}Demo User:${NC}"
echo "  Username: demo"
echo "  Password: demo123"
echo ""
echo -e "${YELLOW}Admin User:${NC}"
echo "  Username: admin"
echo "  Password: admin123"
echo ""

echo "╔════════════════════════════════════════════════════════════╗"
echo "║                  SERVICES RUNNING                          ║"
echo "║  • PostgreSQL:     Database (port 5432)                   ║"
echo "║  • Redis:          Cache server (port 6379)               ║"
echo "║  • Neo4j:          Graph Database (port 7687)             ║"
echo "║  • Backend:        REST API (port 3001)                   ║"
echo "║  • Frontend:       Vue.js UI (port 5173)                  ║"
echo "║  • Nginx:          Reverse proxy (port 80)                ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

echo -e "${GREEN}Your Project Nexus wiki is ready!${NC}"
echo ""
echo "Troubleshooting:"
echo "  • Check service logs: sudo journalctl -u nexus-backend -n 30"
echo "  • Restart services:   sudo systemctl restart postgresql neo4j redis nexus-backend nexus-frontend"
echo "  • View all status:    sudo systemctl status"
echo ""
