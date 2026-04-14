# Project Nexus Wiki - Access Instructions

## You are now running NixOS with Project Nexus!

### QUICK START (Run on NixOS Terminal)

1. **Verify services are running:**
   ```bash
   sudo systemctl status postgresql neo4j redis nexus-backend
   ```
   All four should show "● active (running)" in green.

2. **Get your IP address:**
   ```bash
   ip addr show
   ```
   Look for "inet" under "ens18:" - this is your IP (e.g., 192.168.178.116)

3. **Test the backend:**
   ```bash
   curl http://localhost:3001/health
   ```

### ACCESS THE WIKI

From your main PC, open your browser and go to:
```
http://<YOUR_IP>:5173
```

Replace `<YOUR_IP>` with the IP from step 2 above.

### LOGIN CREDENTIALS

**Demo User:**
- Username: `demo`
- Password: `demo123`

**Admin User:**
- Username: `admin`
- Password: `admin123`

### WHAT'S RUNNING

- **Frontend**: Vue.js app on port 5173
- **Backend API**: Node.js/Express on port 3001
- **Database**: PostgreSQL (nexus_db)
- **Graph DB**: Neo4j on port 7687
- **Cache**: Redis on port 6379

### TROUBLESHOOTING

If services aren't running:
```bash
sudo systemctl restart postgresql neo4j redis nexus-backend
sudo journalctl -u nexus-backend -n 20  # View backend logs
```

### DATABASE CREDENTIALS (for administrators)

- PostgreSQL user: `nexus_user`
- PostgreSQL password: `nexus_password`
- Neo4j user: `neo4j`
- Neo4j password: `nexus_password`

---

**That's it! Your wiki is ready to use.**
