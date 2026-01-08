-- ============================================================================
-- INVENTORY TABLE CREATION SCRIPT
-- ============================================================================
-- Purpose: Inventory master data - Serial + Part + Dealer combinations
-- Dependencies: Requires 'account' table to exist
-- ============================================================================

-- Drop table if exists (use with caution in production)
DROP TABLE IF EXISTS inventory CASCADE;

-- Create inventory table
CREATE TABLE inventory (
    unique_id VARCHAR(255) PRIMARY KEY NOT NULL,
    serial__number VARCHAR(255),
    part__number VARCHAR(255),
    fch__partyid VARCHAR(255) NOT NULL,
    
    CONSTRAINT fk_inventory_account 
        FOREIGN KEY (fch__partyid) 
        REFERENCES account(fch__partyid)
);

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON TABLE inventory IS 'Inventory master data - Serial + Part + Dealer combinations';
COMMENT ON COLUMN inventory.unique_id IS 'Primary Key - Unique identifier for each inventory record';
COMMENT ON COLUMN inventory.serial__number IS 'Serial number of the item';
COMMENT ON COLUMN inventory.part__number IS 'Part number of the item';
COMMENT ON COLUMN inventory.fch__partyid IS 'Foreign Key to account table';

-- ============================================================================
-- VERIFICATION
-- ============================================================================

-- Verify table creation
SELECT 
    'inventory' as table_name,
    COUNT(*) as row_count,
    pg_size_pretty(pg_total_relation_size('inventory')) as total_size
FROM inventory;

