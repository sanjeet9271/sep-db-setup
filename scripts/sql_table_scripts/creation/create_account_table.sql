-- ============================================================================
-- ACCOUNT TABLE CREATION SCRIPT
-- ============================================================================
-- Purpose: Account/Dealer master data
-- Dependencies: None (base table)
-- ============================================================================

-- Drop table if exists (use with caution in production)
DROP TABLE IF EXISTS account CASCADE;

-- Create account table
CREATE TABLE account (
    fch__partyid VARCHAR(255) PRIMARY KEY NOT NULL,
    account__number VARCHAR(255),
    name VARCHAR(255),
    account__type VARCHAR(255),
    primary__address VARCHAR(500),
    primary__city VARCHAR(255),
    primary__state VARCHAR(255),
    primary__zip VARCHAR(255)
);

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON TABLE account IS 'Account/Dealer master data';
COMMENT ON COLUMN account.fch__partyid IS 'Primary Key - Unique Party ID from FCH system';
COMMENT ON COLUMN account.account__number IS 'Account number';
COMMENT ON COLUMN account.name IS 'Account/Dealer name';
COMMENT ON COLUMN account.account__type IS 'Type of account';
COMMENT ON COLUMN account.primary__address IS 'Primary address';
COMMENT ON COLUMN account.primary__city IS 'Primary city';
COMMENT ON COLUMN account.primary__state IS 'Primary state';
COMMENT ON COLUMN account.primary__zip IS 'Primary ZIP code';

-- ============================================================================
-- VERIFICATION
-- ============================================================================

-- Verify table creation
SELECT 
    'account' as table_name,
    COUNT(*) as row_count,
    pg_size_pretty(pg_total_relation_size('account')) as total_size
FROM account;

