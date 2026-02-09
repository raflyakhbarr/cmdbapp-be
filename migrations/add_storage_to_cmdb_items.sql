-- Migration: Add storage column to cmdb_items
-- Description: Menambahkan kolom storage untuk menyimpan informasi kapasitas storage item
-- Date: 2025-02-09

-- Cek apakah kolom storage sudah ada, jika belum maka tambahkan
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_name = 'cmdb_items'
        AND column_name = 'storage'
    ) THEN
        ALTER TABLE cmdb_items
        ADD COLUMN storage JSONB DEFAULT NULL;

        RAISE NOTICE 'Kolom storage berhasil ditambahkan ke tabel cmdb_items';
    ELSE
        RAISE NOTICE 'Kolom storage sudah ada di tabel cmdb_items';
    END IF;
END $$;

-- Contoh struktur data storage yang valid:
-- {
--   "total": 512,        // dalam GB
--   "used": 256,         // dalam GB
--   "unit": "GB",
--   "partitions": [
--     { "name": "C:", "total": 256, "used": 128, "unit": "GB" },
--     { "name": "D:", "total": 256, "used": 128, "unit": "GB" }
--   ]
-- }

-- Komentar pada tabel
COMMENT ON COLUMN cmdb_items.storage IS 'Informasi storage item dalam format JSONB. Struktur: {total, used, unit, partitions?}';
