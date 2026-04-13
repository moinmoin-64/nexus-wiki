{ config, pkgs, lib, ... }:

{
  services.nginx = {
    enable = true;
    package = pkgs.nginx;

    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    recommendedOptimisation = true;
    recommendedGzipSettings = true;

    virtualHosts = {
      # Redirect HTTP to HTTPS
      "wiki-oliver.duckdns.org" = {
        forceSSL = true;
        enableACME = true;
        acmeData = "/var/lib/acme";

        locations."/" = {
          proxyPass = "http://127.0.0.1:3000";
          proxyWebsockets = true;
          extraConfig = ''
            proxy_set_header Connection "Upgrade";
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_connect_timeout 60s;
            proxy_send_timeout 60s;
            proxy_read_timeout 60s;
          '';
        };

        # API Endpoints
        locations."/api/" = {
          proxyPass = "http://127.0.0.1:3001";
          extraConfig = ''
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
          '';
        };

        # WebSocket support for real-time collaboration
        locations."/ws" = {
          proxyPass = "http://127.0.0.1:3002";
          extraConfig = ''
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "Upgrade";
            proxy_set_header Host $host;
            proxy_read_timeout 86400;
          '';
        };

        # Neo4j Graph API (optional)
        locations."/graph/" = {
          proxyPass = "http://127.0.0.1:7474";
          extraConfig = ''
            proxy_set_header Host $host;
            auth_request /auth;
          '';
        };

        # Authentication gateway
        locations."/auth" = {
          internal = true;
          proxyPass = "http://127.0.0.1:3001/auth/verify";
        };
      };

      # Localhost fallback (for local testing)
      "localhost" = {
        listen = [ { addr = "127.0.0.1"; port = 8080; } ];
        
        locations."/" = {
          proxyPass = "http://127.0.0.1:3000";
        };
      };
    };

    # Global settings
    apparmor = "complain";
    
    httpConfig = ''
      # Logging
      access_log /var/log/nginx/access.log combined buffer=32k flush=5s;
      error_log /var/log/nginx/error.log warn;

      # Performance
      sendfile on;
      tcp_nopush on;
      tcp_nodelay on;
      types_hash_max_size 2048;
      client_max_body_size 100M;
      
      # Security
      server_tokens off;
      add_header X-Frame-Options "SAMEORIGIN" always;
      add_header X-Content-Type-Options "nosniff" always;
      add_header X-XSS-Protection "1; mode=block" always;
      add_header Referrer-Policy "strict-origin-when-cross-origin" always;
      add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline';" always;
      
      # Gzip
      gzip on;
      gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
      gzip_vary on;
      gzip_comp_level 6;
    '';
  };

  # ACME Let's Encrypt Configuration
  security.acme = {
    acceptTerms = true;
    defaults.email = "nexus@wiki-oliver.duckdns.org";
    defaults.webroot = "/var/www/acme";
  };

  # Create webroot for ACME
  systemd.tmpfiles.rules = [
    "d /var/www/acme 0755 nginx nginx -"
  ];

  # Open ports
  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
