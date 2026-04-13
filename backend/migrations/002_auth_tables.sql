/* Migration 2: Authentication Tables */

-- Refresh tokens for JWT revocation
CREATE TABLE IF NOT EXISTS nexus.refresh_tokens (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES nexus.users(id) ON DELETE CASCADE,
  token TEXT NOT NULL UNIQUE,
  expires_at TIMESTAMP NOT NULL,
  revoked_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Index for token lookups
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_user ON nexus.refresh_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_token ON nexus.refresh_tokens(token);
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_expires_at ON nexus.refresh_tokens(expires_at);

-- Sessions table for additional tracking
CREATE TABLE IF NOT EXISTS nexus.sessions (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES nexus.users(id) ON DELETE CASCADE,
  session_token VARCHAR(255) UNIQUE NOT NULL,
  ip_address INET,
  user_agent TEXT,
  device_info JSONB,
  last_activity TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  expires_at TIMESTAMP NOT NULL,
  revoked_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_sessions_user ON nexus.sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_sessions_token ON nexus.sessions(session_token);
CREATE INDEX IF NOT EXISTS idx_sessions_expires_at ON nexus.sessions(expires_at);

-- Login attempts table (for brute force detection)
CREATE TABLE IF NOT EXISTS nexus.login_attempts (
  id SERIAL PRIMARY KEY,
  username VARCHAR(100) NOT NULL,
  ip_address INET,
  success BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_login_attempts_username ON nexus.login_attempts(username);
CREATE INDEX IF NOT EXISTS idx_login_attempts_ip ON nexus.login_attempts(ip_address);
CREATE INDEX IF NOT EXISTS idx_login_attempts_created_at ON nexus.login_attempts(created_at);

-- Workflow status history
CREATE TABLE IF NOT EXISTS nexus.document_status_history (
  id SERIAL PRIMARY KEY,
  document_id INTEGER NOT NULL REFERENCES nexus.documents(id) ON DELETE CASCADE,
  from_status VARCHAR(50),
  to_status VARCHAR(50) NOT NULL,
  changed_by INTEGER REFERENCES nexus.users(id) ON DELETE SET NULL,
  reason TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_document_status_history_doc ON nexus.document_status_history(document_id);
CREATE INDEX IF NOT EXISTS idx_document_status_history_created_at ON nexus.document_status_history(created_at);
