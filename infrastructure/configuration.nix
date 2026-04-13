# NixOS Configuration - Project Nexus TUI Appliance
# Minimal system: Only Nexus server, Pure TUI, Auto-start on boot

{ config, pkgs, lib, ... }:

{
  imports = [];

  # Minimal system
  minimal.enable = true;

  # Kernel & Boot
  boot = {
    loader.grub.enable = true;
    loader.grub.device = "/dev/sda";
    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [ "quiet" "no_console_suspend" ];
    # Skip splash screen
    consoleLogLevel = 0;
    initrd.verbose = false;
  };

  # Networking
  networking = {
    hostName = "nexus";
    useDHCP = true;
    interfaces = {
      eth0.useDHCP = true;
    };
    firewall.enable = true;
    firewall.allowedTCPPorts = [ 22 80 443 3001 7687 7474 5432 ];
    firewall.allowedUDPPorts = [];
  };

  # System clock
  time.timeZone = "UTC";
  services.chrony.enable = true;

  # Users - NO passwd, key-based SSH only
  users = {
    mutableUsers = false;
    users = {
      root = {
        initialHashedPassword = "!";
        openssh.authorizedKeys.keys = [];
      };
      nexus = {
        isSystemUser = true;
        isNormalUser = true;
        home = "/home/nexus";
        createHome = true;
        group = "nexus";
        extraGroups = [ "wheel" "docker" ];
        shell = pkgs.bash;
        initialHashedPassword = "!";
        openssh.authorizedKeys.keys = [];
      };
    };
    groups.nexus = {};
  };

  # SSH - Hardened
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PubkeyAuthentication = true;
      PermitRootLogin = "no";
      X11Forwarding = false;
      AllowUsers = "nexus";
    };
    ports = [ 22 ];
  };

  # No GUI - Remove everything graphical
  services.xserver.enable = false;
  services.displayManager.enable = false;
  
  # Locale
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.supportedLocales = [ "en_US.UTF-8/UTF-8" ];

  # PostgreSQL
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_15;
    port = 5432;
    dataDir = "/var/lib/postgresql/15";
    
    initialScript = pkgs.writeText "init.sql" ''
      CREATE USER nexus_user WITH PASSWORD 'nexus_password';
      CREATE DATABASE nexus_db OWNER nexus_user;
      
      \c nexus_db
      
      CREATE SCHEMA nexus;
      GRANT ALL PRIVILEGES ON SCHEMA nexus TO nexus_user;
      GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA nexus TO nexus_user;
      GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA nexus TO nexus_user;
    '';

    settings = {
      max_connections = 100;
      shared_buffers = "256MB";
      work_mem = "16MB";
      maintenance_work_mem = "64MB";
      synchronous_commit = "on";
      wal_buffers = "16MB";
    };
  };

  users.users.postgres.initialHashedPassword = "!";

  # Neo4j Graph Database
  services.neo4j = {
    enable = true;
    package = pkgs.neo4j;
    port = 7687;
    dataDir = "/var/lib/neo4j";
    settings = {
      "server.memory.heap.initial_size" = "512m";
      "server.memory.heap.max_size" = "1024m";
      "dbms.security.auth_enabled" = true;
    };
  };

  # Redis (for rate limiting)
  services.redis = {
    enable = true;
    port = 6379;
    bind = "127.0.0.1";
  };

  # Node.js & NPM
  nodejs = pkgs.nodejs_18;

  # Nexus Backend Service
  systemd.services.nexus-backend = {
    description = "Project Nexus Backend API";
    after = [ "network.target" "postgresql.service" "neo4j.service" "redis.service" ];
    wants = [ "postgresql.service" "neo4j.service" "redis.service" ];
    wantedBy = [ "multi-user.target" ];
    
    preStart = ''
      mkdir -p /opt/nexus/backend
      mkdir -p /var/log/nexus
      mkdir -p /var/lib/nexus
      chown -R nexus:nexus /opt/nexus /var/log/nexus /var/lib/nexus
    '';

    script = ''
      export NODE_ENV=production
      export PORT=3001
      export LOG_LEVEL=info
      export POSTGRES_URL="postgresql://nexus_user:nexus_password@localhost:5432/nexus_db"
      export NEO4J_BOLT_URL="bolt://localhost:7687"
      export NEO4J_USER=neo4j
      export NEO4J_PASSWORD=nexus_password
      export JWT_SECRET="change-me-to-secret-key"
      export REDIS_HOST=localhost
      export REDIS_PORT=6379
      
      cd /opt/nexus/backend
      ${pkgs.nodejs_18}/bin/node dist/api/server.js
    '';

    serviceConfig = {
      Type = "simple";
      User = "nexus";
      Group = "nexus";
      Restart = "always";
      RestartSec = 10;
      StandardOutput = "journal";
      StandardError = "journal";
      EnvironmentFile = "/etc/nexus/backend.env";
      WorkingDirectory = "/opt/nexus/backend";
    };
  };

  # Nexus Graph Mirror Service (Python)
  systemd.services.nexus-graph-mirror = {
    description = "Project Nexus Graph Mirror Service";
    after = [ "postgresql.service" "neo4j.service" ];
    wants = [ "postgresql.service" "neo4j.service" ];
    wantedBy = [ "multi-user.target" ];
    
    script = ''
      export POSTGRES_URL="postgresql://nexus_user:nexus_password@localhost:5432/nexus_db"
      export NEO4J_BOLT_URL="bolt://localhost:7687"
      export NEO4J_PASSWORD=nexus_password
      
      ${pkgs.python3}/bin/python3 /opt/nexus/backend/services/graph-mirror.py
    '';

    serviceConfig = {
      Type = "simple";
      User = "nexus";
      Group = "nexus";
      Restart = "always";
      RestartSec = 10;
      StandardOutput = "journal";
      StandardError = "journal";
    };
  };

  # Nginx Reverse Proxy
  services.nginx = {
    enable = true;
    package = pkgs.nginx;
    
    httpConfig = ''
      upstream backend {
        server 127.0.0.1:3001;
      }

      server {
        listen 80;
        listen [::]:80;
        server_name _;

        location / {
          proxy_pass http://backend;
          proxy_http_version 1.1;
          proxy_set_header Upgrade $http_upgrade;
          proxy_set_header Connection "upgrade";
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $scheme;
        }

        location /ws {
          proxy_pass http://backend;
          proxy_http_version 1.1;
          proxy_set_header Upgrade $http_upgrade;
          proxy_set_header Connection "upgrade";
          proxy_read_timeout 86400;
        }
      }
    '';
  };

  # Status Monitor (TUI Dashboard)
  systemd.services.nexus-monitor = {
    description = "Project Nexus TUI Monitor";
    after = [ "multi-user.target" ];
    wantedBy = [];  # Manual start or via shell profile
    
    script = ''
      ${pkgs.bash}/bin/bash -c 'while true; do
        clear
        echo "╔════════════════════════════════════════╗"
        echo "║   Project Nexus - TUI Monitor          ║"
        echo "║   $(date +%Y-%m-%d\ %H:%M:%S)                     ║"
        echo "╚════════════════════════════════════════╝"
        echo ""
        echo "🔷 System Status:"
        echo "─────────────────────────────────────────"
        ${pkgs.systemd}/bin/systemctl status nexus-backend --no-pager | head -5
        echo ""
        echo "🗄️  Services:"
        echo "─────────────────────────────────────────"
        ${pkgs.systemd}/bin/systemctl status postgresql --no-pager | head -2
        ${pkgs.systemd}/bin/systemctl status neo4j --no-pager | head -2
        ${pkgs.systemd}/bin/systemctl status nginx --no-pager | head -2
        echo ""
        echo "📊 Resources:"
        echo "─────────────────────────────────────────"
        echo "Uptime: $(${pkgs.uptime}/bin/uptime -p)"
        echo "Disk:   $(${pkgs.coreutils}/bin/df -h / | tail -1 | ${pkgs.gawk}/bin/awk '\''{print $5}'\'')"
        echo "Memory: $(${pkgs.procps}/bin/free -h | grep Mem | ${pkgs.gawk}/bin/awk '\''{print $3 "/" $2}'\'')"
        echo ""
        sleep 5
      done'
    '';

    serviceConfig = {
      Type = "simple";
      User = "nexus";
      StandardOutput = "journal";
      StandardError = "journal";
    };
  };

  # Auto-login bash profile
  users.users.nexus.homeDirectory = "/home/nexus";

  # Shell profile for auto-starting monitor
  environment.etc."profile.d/nexus-startup.sh" = {
    text = ''
      if [ -z "$NEXUS_STARTUP_DONE" ]; then
        export NEXUS_STARTUP_DONE=1
        clear
        echo "╔════════════════════════════════════════╗"
        echo "║  🚀 Project Nexus Server Initializing  ║"
        echo "║  Waiting for services to start...      ║"
        echo "╚════════════════════════════════════════╝"
        echo ""
        sleep 3
        
        # Wait for backend to be ready
        until curl -s http://localhost:3001/health > /dev/null 2>&1; do
          echo "⏳ Waiting for backend... ($(date +%T))"
          sleep 2
        done
        
        echo "✅ All services ready!"
        echo ""
        echo "🌐 Web UI:  http://localhost"
        echo "🔌 API:     http://localhost:3001"
        echo "📊 PG:      localhost:5432"
        echo "🔷 Neo4j:   localhost:7687"
        echo ""
        echo "📝 Logs: journalctl -u nexus-backend -f"
        echo "📊 Status: systemctl status"
        echo "🛑 Shutdown: systemctl poweroff"
        echo ""
      fi
    '';
  };

  # getty auto-login
  systemd.services."getty@tty1" = {
    serviceConfig = {
      ExecStart = [
        ""
        "${pkgs.util-linux}/sbin/agetty --autologin nexus --noclear %I linux"
      ];
    };
  };

  # Environment
  environment.systemPackages = with pkgs; [
    curl
    wget
    htop
    iotop
    tmux
    vim
    git
    jq
    postgresql
    nodejs_18
    npm
    python3
    systemd
    coreutils
    gawk
  ];

  # Setup scripts in /opt/nexus/scripts/
  system.activationScripts.copyNexusScripts = {
    text = ''
      mkdir -p /opt/nexus/scripts
      cat > /opt/nexus/scripts/update-nexus.sh << 'EOFUPDATE'
${builtins.readFile ../scripts/update-nexus.sh}
EOFUPDATE
      chmod +x /opt/nexus/scripts/update-nexus.sh
      
      # Create symlink for convenience
      mkdir -p /usr/local/bin
      ln -sf /opt/nexus/scripts/update-nexus.sh /usr/local/bin/update || true
    '';
  };

  # Disable unnecessary services
  services.logind.extraConfig = ''
    HandleLidSwitch=ignore
    HandleLidSwitchExternalPower=ignore
    HandleLidSwitchDocked=ignore
  '';

  # Systemd settings
  systemd.coredump.enable = false;

  # Nexus Update Service
  systemd.units."nexus-update.service".text = ''
    [Unit]
    Description=Project Nexus Automatic Update Service
    After=network-online.target postgresql.service neo4j.service
    Wants=network-online.target

    [Service]
    Type=oneshot
    User=nexus
    Group=nexus
    Environment="PATH=/opt/nexus/backend/node_modules/.bin:${pkgs.nodejs_18}/bin:${pkgs.git}/bin:/usr/bin:/bin"
    ExecStart=${pkgs.bash}/bin/bash /opt/nexus/scripts/update-nexus.sh --cron
    StandardOutput=journal
    StandardError=journal
  '';

  # Nexus Update Timer (Every Monday at 02:00 UTC)
  systemd.units."nexus-update.timer".text = ''
    [Unit]
    Description=Project Nexus Weekly Update Timer
    Documentation=https://github.com/moinmoin-64/nexus-wiki

    [Timer]
    OnCalendar=Mon *-*-* 02:00:00
    Persistent=true
    AccuracySec=1min

    [Install]
    WantedBy=timers.target
  '';

  systemd.timers."nexus-update" = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "Mon *-*-* 02:00:00";
      Persistent = true;
      AccuracySec = "1min";
    };
  };

  # Security
  security.sudo.enable = true;
  security.sudo.wheelNeedsPassword = false;

  # Nix settings
  nix = {
    settings = {
      allowed-users = [ "nexus" ];
      auto-optimise-store = true;
      cores = 0;
      max-jobs = "auto";
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "-d";
    };
  };

  # System state
  system.stateVersion = "23.11";
}
