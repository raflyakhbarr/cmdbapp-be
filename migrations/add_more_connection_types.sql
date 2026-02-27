-- Migration: Add More Connection Types
-- Menambahkan tipe relasi tambahan untuk CMDB

-- 1. Tambah tipe baru ke ENUM
ALTER TYPE connection_type_enum ADD VALUE IF NOT EXISTS 'backed_up_by';
ALTER TYPE connection_type_enum ADD VALUE IF NOT EXISTS 'hosted_on';
ALTER TYPE connection_type_enum ADD VALUE IF NOT EXISTS 'hosting';
ALTER TYPE connection_type_enum ADD VALUE IF NOT EXISTS 'licensed_by';
ALTER TYPE connection_type_enum ADD VALUE IF NOT EXISTS 'licensing';
ALTER TYPE connection_type_enum ADD VALUE IF NOT EXISTS 'part_of';
ALTER TYPE connection_type_enum ADD VALUE IF NOT EXISTS 'comprised_of';
ALTER TYPE connection_type_enum ADD VALUE IF NOT EXISTS 'related_to';
ALTER TYPE connection_type_enum ADD VALUE IF NOT EXISTS 'preceding';
ALTER TYPE connection_type_enum ADD VALUE IF NOT EXISTS 'succeeding';
ALTER TYPE connection_type_enum ADD VALUE IF NOT EXISTS 'encrypted_by';
ALTER TYPE connection_type_enum ADD VALUE IF NOT EXISTS 'encrypting';
ALTER TYPE connection_type_enum ADD VALUE IF NOT EXISTS 'authenticated_by';
ALTER TYPE connection_type_enum ADD VALUE IF NOT EXISTS 'authenticating';
ALTER TYPE connection_type_enum ADD VALUE IF NOT EXISTS 'monitoring';
ALTER TYPE connection_type_enum ADD VALUE IF NOT EXISTS 'monitored_by';
ALTER TYPE connection_type_enum ADD VALUE IF NOT EXISTS 'load_balanced_by';
ALTER TYPE connection_type_enum ADD VALUE IF NOT EXISTS 'load_balancing';
ALTER TYPE connection_type_enum ADD VALUE IF NOT EXISTS 'failing_over_to';
ALTER TYPE connection_type_enum ADD VALUE IF NOT EXISTS 'failover_from';
ALTER TYPE connection_type_enum ADD VALUE IF NOT EXISTS 'replicating_to';
ALTER TYPE connection_type_enum ADD VALUE IF NOT EXISTS 'replicated_by';
ALTER TYPE connection_type_enum ADD VALUE IF NOT EXISTS 'proxying_for';
ALTER TYPE connection_type_enum ADD VALUE IF NOT EXISTS 'proxied_by';
ALTER TYPE connection_type_enum ADD VALUE IF NOT EXISTS 'routed_through';
ALTER TYPE connection_type_enum ADD VALUE IF NOT EXISTS 'routing';

-- 2. Insert definitions untuk tipe baru
INSERT INTO connection_type_definitions (type_slug, label, description, icon, default_direction, color, show_arrow) VALUES
  ('backed_up_by', 'Backed Up By', 'Source item is backed up by target item', 'refresh-cw', 'backward', '#14b8a6', true),
  ('hosted_on', 'Hosted On', 'Source item is hosted on target item (VM on physical server)', 'server', 'forward', '#6366f1', true),
  ('hosting', 'Hosting', 'Source item hosts target item', 'server', 'backward', '#6366f1', true),
  ('licensed_by', 'Licensed By', 'Source item uses license from target item', 'key', 'backward', '#eab308', true),
  ('licensing', 'Licensing', 'Source item provides license to target item', 'key', 'forward', '#eab308', true),
  ('part_of', 'Part Of', 'Source item is part of target item (component relationship)', 'puzzle', 'forward', '#a855f7', true),
  ('comprised_of', 'Comprised Of', 'Source item is composed of target item', 'puzzle', 'backward', '#a855f7', true),
  ('related_to', 'Related To', 'Source item is related to target item (general relationship)', 'link', 'bidirectional', '#94a3b8', true),
  ('preceding', 'Preceding', 'Source item precedes target item in workflow', 'arrow-up', 'forward', '#f97316', true),
  ('succeeding', 'Succeeding', 'Source item succeeds target item in workflow', 'arrow-down', 'backward', '#f97316', true),
  ('encrypted_by', 'Encrypted By', 'Source item is encrypted by target item', 'lock', 'backward', '#be123c', true),
  ('encrypting', 'Encrypting', 'Source item encrypts target item', 'lock', 'forward', '#be123c', true),
  ('authenticated_by', 'Authenticated By', 'Source item is authenticated by target item', 'shield-check', 'backward', '#059669', true),
  ('authenticating', 'Authenticating', 'Source item authenticates target item', 'shield-check', 'forward', '#059669', true),
  ('monitoring', 'Monitoring', 'Source item monitors target item', 'eye', 'forward', '#ec4899', true),
  ('monitored_by', 'Monitored By', 'Source item is monitored by target item', 'eye', 'backward', '#ec4899', true),
  ('load_balanced_by', 'Load Balanced By', 'Source item is load balanced by target item', 'scale', 'backward', '#8b5cf6', true),
  ('load_balancing', 'Load Balancing', 'Source item load balances target item', 'scale', 'forward', '#8b5cf6', true),
  ('failing_over_to', 'Failing Over To', 'Source item fails over to target item', 'zap', 'forward', '#ef4444', true),
  ('failover_from', 'Failover From', 'Source item is failover source for target item', 'zap', 'backward', '#ef4444', true),
  ('replicating_to', 'Replicating To', 'Source item replicates data to target item', 'database', 'forward', '#06b6d4', true),
  ('replicated_by', 'Replicated By', 'Source item is replicated by target item', 'database', 'backward', '#06b6d4', true),
  ('proxying_for', 'Proxying For', 'Source item proxies requests for target item', 'workflow', 'forward', '#f59e0b', true),
  ('proxied_by', 'Proxied By', 'Source item is proxied by target item', 'workflow', 'backward', '#f59e0b', true),
  ('routed_through', 'Routed Through', 'Source item is routed through target item', 'route', 'forward', '#10b981', true),
  ('routing', 'Routing', 'Source item routes target item', 'route', 'backward', '#10b981', true)
ON CONFLICT (type_slug) DO NOTHING;

-- 3. Update index
CREATE INDEX IF NOT EXISTS idx_connections_type_workspace ON connections(connection_type, workspace_id);
