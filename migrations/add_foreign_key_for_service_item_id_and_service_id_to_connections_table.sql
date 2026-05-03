-- Add foreign key for target_service_id -> services(id)
ALTER TABLE connections
ADD CONSTRAINT connections_target_service_id_fkey
FOREIGN KEY (target_service_id) REFERENCES services(id) ON DELETE CASCADE;

-- Add foreign key for target_service_item_id -> service_items(id)
ALTER TABLE connections
ADD CONSTRAINT connections_target_service_item_id_fkey
FOREIGN KEY (target_service_item_id) REFERENCES service_items(id) ON DELETE CASCADE;