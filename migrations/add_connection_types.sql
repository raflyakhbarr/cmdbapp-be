-- Migration: Add Connection Type Support
-- Menambahkan tipe relasi dan arah koneksi

-- 1. Buat ENUM untuk connection types
CREATE TYPE connection_type_enum AS ENUM (
  'depends_on',           -- Item bergantung pada target
  'consumed_by',         -- Item dikonsumsi oleh target
  'connects_to',         -- Koneksi jaringan
  'contains',            -- Hirarki/komposisi (parent-child)
  'managed_by',          -- Manajemen
  'data_flow_to',        -- Aliran data
  'backup_to'             -- Backup
);

-- 2. Tambah kolom ke tabel connections
ALTER TABLE connections
  ADD COLUMN IF NOT EXISTS connection_type connection_type_enum DEFAULT 'depends_on',
  ADD COLUMN IF NOT EXISTS direction VARCHAR(20) DEFAULT 'forward';

-- 3. Buat tabel definisi connection type (untuk konfigurasi UI)
CREATE TABLE IF NOT EXISTS connection_type_definitions (
  id SERIAL PRIMARY KEY,
  type_slug connection_type_enum NOT NULL UNIQUE,
  label VARCHAR(50) NOT NULL,
  description TEXT,
  icon VARCHAR(50),
  default_direction VARCHAR(20) DEFAULT 'forward',
  color VARCHAR(20) DEFAULT '#3b82f6',
  show_arrow BOOLEAN DEFAULT true,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 4. Insert default definitions
INSERT INTO connection_type_definitions (type_slug, label, description, icon, default_direction, color, show_arrow) VALUES
  ('depends_on', 'Depends On', 'Source item depends on target item (jika target mati, source terdampak)', 'arrow-up-right', 'forward', '#3b82f6', true),
  ('consumed_by', 'Consumed By', 'Source item is consumed by target item (resource usage)', 'arrow-down-right', 'backward', '#f59e0b', true),
  ('connects_to', 'Connects To', 'Network connection between items', 'link', 'bidirectional', '#8b5cf6', true),
  ('contains', 'Contains', 'Source contains target (parent-child relationship)', 'layers', 'forward', '#10b981', true),
  ('managed_by', 'Managed By', 'Source is managed by target', 'shield', 'backward', '#a855f7', true),
  ('data_flow_to', 'Data Flow To', 'Data flows from source to target', 'trending-up', 'forward', '#06b6d4', true),
  ('backup_to', 'Backup To', 'Source backs up to target', 'refresh-cw', 'forward', '#14b8a6', true)
ON CONFLICT (type_slug) DO NOTHING;

-- 5. Create index for better query performance
CREATE INDEX IF NOT EXISTS idx_connections_type ON connections(connection_type);
CREATE INDEX IF NOT EXISTS idx_connections_direction ON connections(direction);

-- 6. Add comment untuk dokumentasi
COMMENT ON COLUMN connections.connection_type IS 'Type of relationship between source and target';
COMMENT ON COLUMN connections.direction IS 'Direction of connection: forward, backward, or bidirectional';