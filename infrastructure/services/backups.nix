{ config, pkgs, lib, ... }:

{
  # Backup Service - PostgreSQL + Git Push
  systemd.services.nexus-backup = {
    description = "Nexus Backup Service - PostgreSQL & Git Commit";
    after = [ "postgresql.service" "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    
    serviceConfig = {
      Type = "oneshot";
      User = "root";
      ExecStart = "${pkgs.bash}/bin/bash -c '${./backup.sh}'";
      StandardOutput = "journal";
      StandardError = "journal";
    };
    
    environment = {
      BACKUP_DIR = "/var/backups/nexus";
      BACKUP_REPO = "git@github.com:YOUR_GITHUB_USERNAME/nexus-backups.git";
      DB_HOST = "localhost";
      DB_PORT = "5432";
      DB_USER = "nexus_user";
      DB_NAME = "nexus_db";
      ENCRYPTION_KEY = "/etc/nexus/backup.key";
    };
  };

  # Backup Timer - Run every 12 hours
  systemd.timers.nexus-backup = {
    description = "Nexus Backup Timer";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "0,12:00";  # Run at 00:00 and 12:00
      OnBootSec = "1min";
      AccuracySec = "1min";
      Persistent = true;
    };
  };

  # Create backup directory
  systemd.tmpfiles.rules = [
    "d /var/backups/nexus 0700 root root -"
    "d /etc/nexus 0700 root root -"
  ];

  # Git SSH Configuration for automated commits
  environment.etc."nexus/git-ssh-config".text = ''
    Host github.com
      HostName github.com
      User git
      IdentityFile /root/.ssh/nexus-backup-key
      StrictHostKeyChecking accept-new
      IdentitiesOnly yes
  '';
}
