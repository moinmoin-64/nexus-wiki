{ config, pkgs, lib, ... }:

{
  services.neo4j = {
    enable = true;
    package = pkgs.neo4j;
    port = 7687;
    
    settings = {
      server.default_listen_address = "127.0.0.1";
      server.bolt.listen_address = "127.0.0.1:7687";
      server.http.listen_address = "127.0.0.1:7474";
      dbms.memory.heap.initial_size = "512m";
      dbms.memory.heap.max_size = "1024m";
      dbms.memory.pagecache.size = "512m";
      
      # Enable query logging
      dbms.logs.query.enabled = true;
      dbms.logs.query.parameter_logging_enabled = false;
    };
  };

  # Neo4j Graph Mirror Service
  systemd.services.nexus-graph-mirror = {
    description = "Nexus Graph Mirror - PostgreSQL to Neo4j Sync";
    after = [ "neo4j.service" "postgresql.service" ];
    wantedBy = [ "multi-user.target" ];
    
    serviceConfig = {
      Type = "simple";
      User = "nexus";
      ExecStart = "${pkgs.python3}/bin/python3 /opt/nexus/services/graph-mirror.py";
      Restart = "on-failure";
      RestartSec = "10s";
      StandardOutput = "journal";
      StandardError = "journal";
    };
    
    environment = {
      POSTGRES_URL = "postgresql://nexus_readonly:@localhost:5432/nexus_db";
      NEO4J_BOLT_URL = "bolt://localhost:7687";
      GRAPH_SYNC_INTERVAL = "300";  # 5 minutes
    };
  };

  # Create graph mirror script directory
  systemd.tmpfiles.rules = [
    "d /opt/nexus/services 0755 nexus nexus -"
  ];
}
