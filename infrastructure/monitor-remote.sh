#!/bin/bash
# Real-time monitoring dashboard for Nexus server over SSH
# Usage: ./monitor-remote.sh <vm-ip>

VM_IP=${1:-"192.168.1.100"}

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

while true; do
  # Clear screen
  clear

  # Header
  echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${GREEN}║          Project Nexus - Remote TUI Monitor                ║${NC}"
  echo -e "${GREEN}║          Connected to: $VM_IP                               ║${NC}"
  echo -e "${GREEN}║          $(date '+%Y-%m-%d %H:%M:%S')                             ║${NC}"
  echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
  echo ""

  # Services status
  echo -e "${YELLOW}🔷 Services:${NC}"
  echo "────────────────────────────────────────────────────────────"
  
  ssh nexus@"$VM_IP" << 'MONITOR' 2>/dev/null
    echo -n "Backend API:     "
    if sudo systemctl is-active --quiet nexus-backend; then
      echo -e "\033[0;32m✓ running\033[0m"
    else
      echo -e "\033[0;31m✗ stopped\033[0m"
    fi

    echo -n "PostgreSQL:      "
    if sudo systemctl is-active --quiet postgresql; then
      echo -e "\033[0;32m✓ running\033[0m"
    else
      echo -e "\033[0;31m✗ stopped\033[0m"
    fi

    echo -n "Neo4j:           "
    if sudo systemctl is-active --quiet neo4j; then
      echo -e "\033[0;32m✓ running\033[0m"
    else
      echo -e "\033[0;31m✗ stopped\033[0m"
    fi

    echo -n "Nginx:           "
    if sudo systemctl is-active --quiet nginx; then
      echo -e "\033[0;32m✓ running\033[0m"
    else
      echo -e "\033[0;31m✗ stopped\033[0m"
    fi

    echo -n "Graph Mirror:    "
    if sudo systemctl is-active --quiet nexus-graph-mirror; then
      echo -e "\033[0;32m✓ running\033[0m"
    else
      echo -e "\033[0;31m✗ stopped\033[0m"
    fi

    echo -n "Redis:           "
    if sudo systemctl is-active --quiet redis; then
      echo -e "\033[0;32m✓ running\033[0m"
    else
      echo -e "\033[0;31m✗ stopped\033[0m"
    fi
MONITOR

  echo ""
  echo -e "${YELLOW}📊 System Resources:${NC}"
  echo "────────────────────────────────────────────────────────────"
  
  ssh nexus@"$VM_IP" << 'RESOURCES' 2>/dev/null
    echo -n "CPU Usage:       "
    top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1

    echo -n "Memory:          "
    free -h | grep Mem | awk '{printf "%s / %s (%.1f%%)\n", $3, $2, ($3/$2)*100}'

    echo -n "Disk Usage /:    "
    df -h / | tail -1 | awk '{printf "%s / %s (%s)\n", $3, $2, $5}'

    echo -n "Uptime:          "
    uptime -p

    echo -n "Load Average:    "
    uptime | awk -F'load average:' '{print $2}'
RESOURCES

  echo ""
  echo -e "${YELLOW}🔌 Network:${NC}"
  echo "────────────────────────────────────────────────────────────"
  
  ssh nexus@"$VM_IP" << 'NETWORK' 2>/dev/null
    echo -n "IP Address:      "
    hostname -I | awk '{print $1}'

    echo -n "Open Ports:      "
    netstat -tulnp 2>/dev/null | grep LISTEN | awk '{print $4}' | cut -d: -f2 | sort | tr '\n' ' ' | sed 's/ /, /g'
    echo ""
NETWORK

  echo ""
  echo -e "${YELLOW}📝 Recent Logs (Backend):${NC}"
  echo "────────────────────────────────────────────────────────────"
  
  ssh nexus@"$VM_IP" "sudo journalctl -u nexus-backend -n 3 --no-pager 2>/dev/null" | tail -3 || echo "No logs"

  echo ""
  echo -e "${GREEN}Commands:${NC}"
  echo "  View full logs:     ssh nexus@$VM_IP 'sudo journalctl -u nexus-backend -f'"
  echo "  Restart backend:    ssh nexus@$VM_IP 'sudo systemctl restart nexus-backend'"
  echo "  SSH to VM:          ssh nexus@$VM_IP"
  echo ""
  echo "Press Ctrl+C to exit. Refreshing in 10 seconds..."
  echo ""

  sleep 10
done
