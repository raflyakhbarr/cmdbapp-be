-- Migration: Fix consumed_by propagation direction
-- Issue: consumed_by was set to target_to_source but semantically source affects target
-- When DB_PERMISSON(source) dies -> PERMISSION(target) should also die via consumed_by
-- This means propagation should be source_to_target

-- Change consumed_by propagation from target_to_source to source_to_target
UPDATE connection_type_definitions SET propagation = 'source_to_target' WHERE type_slug = 'consumed_by';

-- Also fix any service_to_service_connections that have incorrect propagation for consumed_by
-- They should use source_to_target for consumed_by
UPDATE service_to_service_connections SET propagation = 'source_to_target' WHERE connection_type = 'consumed_by' AND propagation = 'target_to_source';

-- Verify the change
SELECT type_slug, propagation FROM connection_type_definitions WHERE type_slug = 'consumed_by';