/* Migration 1: Initial Schema */

-- Create schema
CREATE SCHEMA IF NOT EXISTS nexus;

-- Enable extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- Documents table
CREATE TABLE IF NOT EXISTS nexus.documents (
  id SERIAL PRIMARY KEY,
  uuid UUID DEFAULT uuid_generate_v4() UNIQUE NOT NULL,
  title VARCHAR(255) NOT NULL,
  content TEXT,
  markdown_raw TEXT,
  status VARCHAR(50) DEFAULT 'draft' CHECK (status IN ('draft', 'review', 'published')),
  created_by INTEGER NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  published_at TIMESTAMP,
  is_deleted BOOLEAN DEFAULT FALSE,
  deleted_at TIMESTAMP
);

-- Document links (for backlink tracking)
CREATE TABLE IF NOT EXISTS nexus.document_links (
  id SERIAL PRIMARY KEY,
  source_doc_id INTEGER NOT NULL REFERENCES nexus.documents(id) ON DELETE CASCADE,
  target_doc_id INTEGER NOT NULL REFERENCES nexus.documents(id) ON DELETE CASCADE,
  link_type VARCHAR(50) DEFAULT 'wikilink' CHECK (link_type IN ('wikilink', 'citation', 'reference')),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(source_doc_id, target_doc_id, link_type)
);

-- Tags table
CREATE TABLE IF NOT EXISTS nexus.tags (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100) UNIQUE NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Document tags (many-to-many)
CREATE TABLE IF NOT EXISTS nexus.document_tags (
  document_id INTEGER NOT NULL REFERENCES nexus.documents(id) ON DELETE CASCADE,
  tag_id INTEGER NOT NULL REFERENCES nexus.tags(id) ON DELETE CASCADE,
  PRIMARY KEY (document_id, tag_id)
);

-- Users table
CREATE TABLE IF NOT EXISTS nexus.users (
  id SERIAL PRIMARY KEY,
  uuid UUID DEFAULT uuid_generate_v4() UNIQUE NOT NULL,
  username VARCHAR(100) UNIQUE NOT NULL,
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  role VARCHAR(50) DEFAULT 'user' CHECK (role IN ('admin', 'user', 'viewer')),
  is_active BOOLEAN DEFAULT TRUE,
  last_login TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Add foreign key to documents.created_by after users table exists
ALTER TABLE nexus.documents ADD CONSTRAINT fk_documents_user
  FOREIGN KEY (created_by) REFERENCES nexus.users(id) ON DELETE SET NULL;

-- Activity log
CREATE TABLE IF NOT EXISTS nexus.activity_log (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES nexus.users(id) ON DELETE SET NULL,
  action VARCHAR(100) NOT NULL,
  resource_type VARCHAR(50),
  resource_id INTEGER,
  details JSONB,
  ip_address INET,
  user_agent TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Full-text search indexes
CREATE INDEX IF NOT EXISTS idx_documents_title_fts ON nexus.documents USING GIN (to_tsvector('english', title));
CREATE INDEX IF NOT EXISTS idx_documents_content_fts ON nexus.documents USING GIN (to_tsvector('english', COALESCE(content, '')));
CREATE INDEX IF NOT EXISTS idx_documents_status ON nexus.documents(status);
CREATE INDEX IF NOT EXISTS idx_documents_created_by ON nexus.documents(created_by);
CREATE INDEX IF NOT EXISTS idx_documents_is_deleted ON nexus.documents(is_deleted);

-- Backlink indexes
CREATE INDEX IF NOT EXISTS idx_document_links_source ON nexus.document_links(source_doc_id);
CREATE INDEX IF NOT EXISTS idx_document_links_target ON nexus.document_links(target_doc_id);

-- Activity log indexes
CREATE INDEX IF NOT EXISTS idx_activity_log_user ON nexus.activity_log(user_id);
CREATE INDEX IF NOT EXISTS idx_activity_log_created_at ON nexus.activity_log(created_at);
CREATE INDEX IF NOT EXISTS idx_activity_log_resource ON nexus.activity_log(resource_type, resource_id);

-- Audit log for compliance
CREATE TABLE IF NOT EXISTS nexus.audit_log (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES nexus.users(id) ON DELETE SET NULL,
  action VARCHAR(100) NOT NULL,
  resource_type VARCHAR(50),
  resource_id INTEGER,
  changes JSONB,
  old_values JSONB,
  new_values JSONB,
  ip_address INET,
  user_agent TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_audit_log_user ON nexus.audit_log(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_log_created_at ON nexus.audit_log(created_at);

-- Grant permissions
GRANT ALL PRIVILEGES ON SCHEMA nexus TO nexus_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA nexus TO nexus_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA nexus TO nexus_user;
