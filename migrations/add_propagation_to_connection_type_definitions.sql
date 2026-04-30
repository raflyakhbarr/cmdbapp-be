-- Migration: Add propagation field to connection_type_definitions
-- Menambahkan field propagation untuk mengontrol bagaimana status di-propagate

-- Add propagation column
ALTER TABLE connection_type_definitions ADD COLUMN IF NOT EXISTS propagation VARCHAR(20) DEFAULT 'both';

-- Add comment for documentation
COMMENT ON COLUMN connection_type_definitions.propagation IS 'Propagation direction: source_to_target, target_to_source, or both (default: both)';

-- Update existing connection types with appropriate propagation values
-- For connection types where source depends on target, propagation should be target_to_source
UPDATE connection_type_definitions SET propagation = 'target_to_source' WHERE type_slug IN (
  'depends_on',
  'consumed_by',
  'hosted_on',
  'licensed_by',
  'authenticated_by',
  'monitored_by',
  'load_balanced_by',
  'failover_from',
  'replicated_by',
  'proxied_by',
  'backed_up_by',
  'encrypted_by',
  'comprised_of',
  'succeeding',
  'managed_by',
  'routing'
);

-- For connection types where source controls/target depends on source, propagation should be source_to_target
UPDATE connection_type_definitions SET propagation = 'source_to_target' WHERE type_slug IN (
  'contains',
  'data_flow_to',
  'backup_to',
  'hosting',
  'licensing',
  'part_of',
  'preceding',
  'encrypting',
  'authenticating',
  'monitoring',
  'load_balancing',
  'failing_over_to',
  'replicating_to',
  'proxying_for',
  'routed_through'
);

-- For bidirectional connection types, propagation should be both
UPDATE connection_type_definitions SET propagation = 'both' WHERE type_slug IN (
  'connects_to',
  'related_to'
);

-- Set default for any remaining NULL
UPDATE connection_type_definitions SET propagation = 'both' WHERE propagation IS NULL;
