# How to Access Project Nexus Wiki

You are now running Project Nexus on NixOS. Follow these steps to access the wiki.

## Quick Start (3 Steps)

### 1. Verify Services Are Running

On the NixOS terminal, run:

```bash
sudo systemctl status postgresql neo4j redis nexus-backend nexus-frontend
```

All five services should show **● active (running)** in green.

If any are inactive, wait 10 seconds and check again (services take time to start).

### 2. Get Your IP Address

Run:

```bash
ip addr show ens18
```

Look for a line starting with `inet` - that's your IP address (e.g., `192.168.178.116`).

### 3. Open the Wiki in Your Browser

On your main computer, open this URL in a browser:

```
http://<YOUR_IP>:5173
```

Replace `<YOUR_IP>` with the IP address from step 2.

## Login Credentials

Once the wiki loads, use these credentials to log in:

### Demo User
- **Username:** `demo`
- **Password:** `demo123`

### Admin User  
- **Username:** `admin`
- **Password:** `admin123`

## Services & Ports

| Service | Port | URL |
|---------|------|-----|
| Frontend | 5173 | http://<IP>:5173 |
| Backend API | 3001 | http://<IP>:3001 |
| PostgreSQL | 5432 | localhost:5432 |
| Neo4j | 7687 | bolt://localhost:7687 |
| Redis | 6379 | localhost:6379 |
| Nginx Proxy | 80 | http://<IP> |

## What's Running

- **Frontend:** Vue.js 3 real-time wiki editor
- **Backend API:** Node.js/Express REST API
- **Database:** PostgreSQL for documents
- **Graph DB:** Neo4j for document relationships
- **Cache:** Redis for sessions & performance

## Verify It's Working

On the NixOS terminal, run:

```bash
curl http://localhost:3001/health
```

You should see a JSON response confirming the API is healthy.

## Troubleshooting

### Services won't start

```bash
sudo systemctl restart postgresql neo4j redis nexus-backend nexus-frontend
sudo journalctl -u nexus-backend -n 50  # View backend logs
sudo journalctl -u nexus-frontend -n 50  # View frontend logs
```

### Can't connect from browser

1. Make sure you're using the correct IP from `ip addr show ens18`
2. Make sure firewall isn't blocking: `sudo systemctl status firewalld`
3. Try accessing the backend directly: `http://<IP>:3001/health`

### Database credentials (admin only)

- **PostgreSQL User:** nexus_user
- **PostgreSQL Password:** nexus_password
- **PostgreSQL Database:** nexus_db
- **Neo4j User:** neo4j
- **Neo4j Password:** nexus_password

---

**You're all set! Enjoy your wiki.**
