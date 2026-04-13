{ config, pkgs, lib, ... }:

{
  services.wiki-js = {
    enable = true;
    package = pkgs.nodejs-18;
    
    # Wiki.js Service Configuration
    systemd.services.wiki-js = {
      description = "Wiki.js Knowledge Base";
      after = [ "network.target" "postgresql.service" ];
      wantedBy = [ "multi-user.target" ];
      
      serviceConfig = {
        Type = "simple";
        User = "wiki-js";
        Group = "wiki-js";
        WorkingDirectory = "/opt/wiki-js";
        ExecStart = "${pkgs.nodejs-18}/bin/node /opt/wiki-js/server/index.js";
        Restart = "on-failure";
        RestartSec = "10s";
        StandardOutput = "journal";
        StandardError = "journal";
        
        # Security
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ReadWritePaths = [ "/opt/wiki-js/data" ];
      };
      
      environment = {
        NODE_ENV = "production";
        DB_TYPE = "postgres";
        DB_HOST = "localhost";
        DB_PORT = "5432";
        DB_USER = "nexus_user";
        DB_NAME = "nexus_db";
        DB_SSL = "true";
        LOG_LEVEL = "info";
      };
    };
  };

  # Create wiki-js user
  users.users.wiki-js = {
    isSystemUser = true;
    group = "wiki-js";
    home = "/opt/wiki-js";
  };

  users.groups.wiki-js = {};

  # Wiki.js installation & setup
  systemd.tmpfiles.rules = [
    "d /opt/wiki-js 0755 wiki-js wiki-js -"
    "d /opt/wiki-js/data 0700 wiki-js wiki-js -"
  ];

  # Install wiki-js via npm
  environment.systemPackages = with pkgs; [
    nodejs-18
  ];
}
