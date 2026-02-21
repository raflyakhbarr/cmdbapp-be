-- Create share_links table for CMDB public sharing feature
CREATE TABLE IF NOT EXISTS share_links (
  id SERIAL PRIMARY KEY,
  token VARCHAR(255) UNIQUE NOT NULL,
  workspace_id INTEGER NOT NULL,
  created_by INTEGER NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  expires_at TIMESTAMP,
  is_active BOOLEAN DEFAULT true,
  access_count INTEGER DEFAULT 0,
  password_hash VARCHAR(255),
  last_accessed_at TIMESTAMP,
  metadata JSONB DEFAULT '{}'::jsonb,
  CONSTRAINT fk_workspace FOREIGN KEY (workspace_id) REFERENCES workspaces(id) ON DELETE CASCADE
);

-- Create index for faster token lookup
CREATE INDEX IF NOT EXISTS idx_share_links_token ON share_links(token);
CREATE INDEX IF NOT EXISTS idx_share_links_workspace ON share_links(workspace_id);
CREATE INDEX IF NOT EXISTS idx_share_links_active ON share_links(is_active, expires_at);

-- Create access_logs table to track share link visits
CREATE TABLE IF NOT EXISTS share_access_logs (
  id SERIAL PRIMARY KEY,
  share_link_id INTEGER NOT NULL,
  visitor_ip VARCHAR(45),
  visitor_user_agent TEXT,
  accessed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_share_link FOREIGN KEY (share_link_id) REFERENCES share_links(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_share_access_logs_link ON share_access_logs(share_link_id);
