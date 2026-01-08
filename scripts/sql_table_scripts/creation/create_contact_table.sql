-- ============================================================================
-- CONTACT TABLE CREATION SCRIPT
-- ============================================================================
-- Purpose: Contact information linked to accounts
-- Dependencies: Requires 'account' table to exist
-- ============================================================================

-- Drop table if exists (use with caution in production)
DROP TABLE IF EXISTS contact CASCADE;

-- Create contact table
CREATE TABLE contact (
    email VARCHAR(255) PRIMARY KEY NOT NULL,
    status VARCHAR(255),
    fch__partyid VARCHAR(255) NOT NULL,
    first__name VARCHAR(255),
    last__name VARCHAR(255),
    phone__number VARCHAR(255),
    phone__number__external VARCHAR(255),
    
    CONSTRAINT fk_contact_account 
        FOREIGN KEY (fch__partyid) 
        REFERENCES account(fch__partyid)
);

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON TABLE contact IS 'Contact information linked to accounts';
COMMENT ON COLUMN contact.email IS 'Primary Key - Contact email address';
COMMENT ON COLUMN contact.status IS 'Contact status (Active, Non-Active, etc.)';
COMMENT ON COLUMN contact.fch__partyid IS 'Foreign Key to account table';
COMMENT ON COLUMN contact.first__name IS 'Contact first name';
COMMENT ON COLUMN contact.last__name IS 'Contact last name';
COMMENT ON COLUMN contact.phone__number IS 'Primary phone number';
COMMENT ON COLUMN contact.phone__number__external IS 'External/alternate phone number';

-- ============================================================================
-- VERIFICATION
-- ============================================================================

-- Verify table creation
SELECT 
    'contact' as table_name,
    COUNT(*) as row_count,
    pg_size_pretty(pg_total_relation_size('contact')) as total_size
FROM contact;

