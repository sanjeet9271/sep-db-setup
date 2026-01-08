-- ============================================================================
-- TECHNICIAN TABLE CREATION SCRIPT
-- ============================================================================
-- Purpose: Technician certifications by product model
-- Dependencies: Requires 'account' table to exist
-- ============================================================================

-- Drop table if exists (use with caution in production)
DROP TABLE IF EXISTS technician CASCADE;

-- Create technician table
CREATE TABLE technician (
    technician__email VARCHAR(255) NOT NULL,
    product__modelname VARCHAR(255) NOT NULL,
    fch__partyid VARCHAR(255) NOT NULL,
    
    PRIMARY KEY (technician__email, product__modelname),
    
    CONSTRAINT fk_technician_account 
        FOREIGN KEY (fch__partyid) 
        REFERENCES account(fch__partyid)
);

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON TABLE technician IS 'Technician certifications by product model';
COMMENT ON COLUMN technician.technician__email IS 'Technician email - Part of composite primary key';
COMMENT ON COLUMN technician.product__modelname IS 'Product model name - Part of composite primary key';
COMMENT ON COLUMN technician.fch__partyid IS 'Foreign Key to account table';

-- ============================================================================
-- VERIFICATION
-- ============================================================================

-- Verify table creation
SELECT 
    'technician' as table_name,
    COUNT(*) as row_count,
    pg_size_pretty(pg_total_relation_size('technician')) as total_size
FROM technician;

