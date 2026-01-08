-- ============================================================================
-- SERVICE_PARTS TABLE CREATION SCRIPT
-- ============================================================================
-- Purpose: Service parts catalog by product model
-- Dependencies: None (base table)
-- ============================================================================

-- Drop table if exists (use with caution in production)
DROP TABLE IF EXISTS service__parts CASCADE;

-- Create service__parts table
CREATE TABLE service__parts (
    product__modelname VARCHAR(255) NOT NULL,
    service__partnumber VARCHAR(255) NOT NULL,
    part__description TEXT,
    gs__business__area VARCHAR(255),
    business__area VARCHAR(255),
    service__type VARCHAR(255),
    part__labour__hours DECIMAL(10, 2),
    part__type VARCHAR(255),
    part__return VARCHAR(255),
    accessory VARCHAR(255),
    ismultipack VARCHAR(255),
    multipack__qty INTEGER,
    
    PRIMARY KEY (product__modelname, service__partnumber)
);

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON TABLE service__parts IS 'Service parts catalog by product model';
COMMENT ON COLUMN service__parts.product__modelname IS 'Product model name - Part of composite primary key';
COMMENT ON COLUMN service__parts.service__partnumber IS 'Service part number - Part of composite primary key';
COMMENT ON COLUMN service__parts.part__description IS 'Description of the service part';
COMMENT ON COLUMN service__parts.gs__business__area IS 'GS business area';
COMMENT ON COLUMN service__parts.business__area IS 'Business area';
COMMENT ON COLUMN service__parts.service__type IS 'Type of service';
COMMENT ON COLUMN service__parts.part__labour__hours IS 'Labor hours for the part';
COMMENT ON COLUMN service__parts.part__type IS 'Type of part';
COMMENT ON COLUMN service__parts.part__return IS 'Return information';
COMMENT ON COLUMN service__parts.accessory IS 'Accessory information';
COMMENT ON COLUMN service__parts.ismultipack IS 'Indicates if multipack';
COMMENT ON COLUMN service__parts.multipack__qty IS 'Multipack quantity';

-- ============================================================================
-- VERIFICATION
-- ============================================================================

-- Verify table creation
SELECT 
    'service__parts' as table_name,
    COUNT(*) as row_count,
    pg_size_pretty(pg_total_relation_size('service__parts')) as total_size
FROM service__parts;

