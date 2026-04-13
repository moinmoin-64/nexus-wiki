{ config, pkgs, lib, ... }:

{
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_15;
    port = 5432;
    
    # Initialize database cluster
    ensureDatabases = [ "nexus_db" ];
    ensureUsers = [
      {
        name = "nexus_user";
        ensurePermissions = {
          "DATABASE nexus_db" = "ALL PRIVILEGES";
        };
      }
      {
        name = "nexus_readonly";
        ensurePermissions = {
          "DATABASE nexus_db" = "CONNECT";
        };
      }
    ];

    # PostgreSQL Configuration
    settings = {
      # Security
      ssl = true;
      ssl_cert_file = "/etc/ssl/certs/postgres.crt";
      ssl_key_file = "/etc/ssl/private/postgres.key";
      
      # Performance
      shared_buffers = "256MB";
      effective_cache_size = "1GB";
      work_mem = "16MB";
      maintenance_work_mem = "64MB";
      
      # WAL & Replication
      wal_level = "replica";
      max_wal_senders = "3";
      wal_keep_segments = "64";
      
      # Full-Text Search
      default_text_search_config = "english";
      
      # Logging
      logging_collector = true;
      log_directory = "log";
      log_filename = "postgresql_%Y-%m-%d_%H%M%S.log";
      log_truncate_on_rotation = true;
      log_rotation_age = "1d";
      log_rotation_size = "100MB";
      log_statement = "none";  # Only log schema changes
      log_min_duration_statement = 5000;  # Only statements > 5s
    };

    # Initialization Script
    initialScript = pkgs.writeText "init-nexus.sql" ''
      -- Create extensions for full-text search
      CREATE EXTENSION IF NOT EXISTS pg_trgm;
      CREATE EXTENSION IF NOT EXISTS unaccent;
      
      -- Create schemas
      CREATE SCHEMA IF NOT EXISTS nexus;
      GRANT USAGE ON SCHEMA nexus TO nexus_user;
      ALTER DEFAULT PRIVILEGES IN SCHEMA nexus GRANT SELECT ON TABLES TO nexus_readonly;
      
      -- Documents Table
      CREATE TABLE IF NOT EXISTS nexus.documents (
        id SERIAL PRIMARY KEY,
        uuid UUID UNIQUE NOT NULL DEFAULT gen_random_uuid(),
        title VARCHAR(255) NOT NULL,
        content TEXT,
        markdown_raw TEXT NOT NULL,
        status VARCHAR(50) DEFAULT 'draft' CHECK (status IN ('draft', 'review', 'published')),
        created_at TIMESTAMP DEFAULT NOW(),
        updated_at TIMESTAMP DEFAULT NOW(),
        created_by INTEGER,
        updated_by INTEGER,
        tags TEXT[] DEFAULT ARRAY[]::TEXT[]
      );
      
      -- Document Links (Wikilinks)
      CREATE TABLE IF NOT EXISTS nexus.document_links (
        id SERIAL PRIMARY KEY,
        source_doc_id INTEGER REFERENCES nexus.documents(id) ON DELETE CASCADE,
        target_doc_id INTEGER REFERENCES nexus.documents(id) ON DELETE CASCADE,
        link_type VARCHAR(50) DEFAULT 'reference',
        created_at TIMESTAMP DEFAULT NOW()
      );
      
      -- Full-Text Search Indexes
      CREATE INDEX IF NOT EXISTS idx_documents_title_ft ON nexus.documents 
        USING gin(to_tsvector('english', title));
      CREATE INDEX IF NOT EXISTS idx_documents_content_ft ON nexus.documents 
        USING gin(to_tsvector('english', content));
      CREATE INDEX IF NOT EXISTS idx_documents_tags ON nexus.documents USING gin(tags);
      
      -- Backlink indexes for fast queries
      CREATE INDEX IF NOT EXISTS idx_document_links_source ON nexus.document_links(source_doc_id);
      CREATE INDEX IF NOT EXISTS idx_document_links_target ON nexus.document_links(target_doc_id);
      
      -- Users Table
      CREATE TABLE IF NOT EXISTS nexus.users (
        id SERIAL PRIMARY KEY,
        uuid UUID UNIQUE NOT NULL DEFAULT gen_random_uuid(),
        username VARCHAR(100) UNIQUE NOT NULL,
        email VARCHAR(255) UNIQUE NOT NULL,
        password_hash VARCHAR(255) NOT NULL,
        role VARCHAR(50) DEFAULT 'user' CHECK (role IN ('admin', 'user', 'viewer')),
        created_at TIMESTAMP DEFAULT NOW(),
        updated_at TIMESTAMP DEFAULT NOW(),
        last_login TIMESTAMP
      );
      
      -- Activity Log for Governance
      CREATE TABLE IF NOT EXISTS nexus.activity_log (
        id SERIAL PRIMARY KEY,
        user_id INTEGER REFERENCES nexus.users(id),
        action VARCHAR(100),
        document_id INTEGER REFERENCES nexus.documents(id),
        old_status VARCHAR(50),
        new_status VARCHAR(50),
        timestamp TIMESTAMP DEFAULT NOW(),
        details JSONB
      );
      
      -- Grant permissions
      GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA nexus TO nexus_user;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA nexus TO nexus_user;
      GRANT SELECT ON ALL TABLES IN SCHEMA nexus TO nexus_readonly;
    '';
  };

  # Backup PostgreSQL
  systemd.timers.postgres-backup-daily = {
    description = "PostgreSQL Daily Backup Timer";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      OnBootSec = "5min";
      Persistent = true;
    };
  };
}
