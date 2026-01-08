-- ============================================================================
-- CASES TABLE CREATION SCRIPT
-- ============================================================================
-- Purpose: Main table for storing Salesforce case data
-- Dependencies: None (base table)
-- ============================================================================

-- Drop table if exists (use with caution in production)
-- DROP TABLE IF EXISTS cases CASCADE;

-- Create cases table
CREATE TABLE cases (
    case_id VARCHAR(18) PRIMARY KEY,              -- Salesforce Case ID (18 characters)
    case_number VARCHAR(20) NOT NULL,             -- Case # (e.g., CS-00012345)
    case_type VARCHAR(50),                        -- WarrantyClaim, RMARepair, etc.
    account_id VARCHAR(50),                       -- Account ID for filtering
    status VARCHAR(50),                           -- Open, In Progress, Closed (not a reserved keyword in PostgreSQL)
    progress INTEGER,                             -- Progress (0-100) [DEPRECATED - FE calculates]
    serial_number VARCHAR(100),                   -- Serial # for display + filtering
    part_number VARCHAR(100),                     -- Part # for display + filtering
    product_description VARCHAR(255),             -- Product description for display
    subject VARCHAR(255),                         -- Subject/title for display (not a reserved keyword in PostgreSQL)
    submitted_at TIMESTAMPTZ,                     -- Original submission date
    case_data JSONB NOT NULL,                     -- Full case details from SF
    synced_at TIMESTAMPTZ NOT NULL DEFAULT NOW()  -- Last sync from Salesforce
);

-- ============================================================================
-- INDEXES FOR PERFORMANCE
-- ============================================================================

-- Index for filtering by account
CREATE INDEX idx_cases_account_id ON cases(account_id);

-- Index for filtering by status
CREATE INDEX idx_cases_status ON cases(status);

-- Index for filtering by case type
CREATE INDEX idx_cases_case_type ON cases(case_type);

-- Index for filtering by serial number
CREATE INDEX idx_cases_serial_number ON cases(serial_number);

-- Index for filtering by part number
CREATE INDEX idx_cases_part_number ON cases(part_number);

-- Index for sorting by submission date
CREATE INDEX idx_cases_submitted_at ON cases(submitted_at DESC);

-- Index for sorting by sync time
CREATE INDEX idx_cases_synced_at ON cases(synced_at DESC);

-- Composite index for common query pattern (account + status)
CREATE INDEX idx_cases_account_status ON cases(account_id, status);

-- GIN index for JSONB queries on case_data
CREATE INDEX idx_cases_case_data ON cases USING GIN(case_data);

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON TABLE cases IS 'Main table for storing Salesforce case data with full JSONB payload';
COMMENT ON COLUMN cases.case_id IS 'Salesforce Case ID (18 characters) - Primary Key';
COMMENT ON COLUMN cases.case_number IS 'Case number for display (e.g., CS-00012345)';
COMMENT ON COLUMN cases.case_type IS 'Type of case: WarrantyClaim, RMARepair, etc.';
COMMENT ON COLUMN cases.account_id IS 'Account ID for filtering and access control';
COMMENT ON COLUMN cases.status IS 'Case status: Open, In Progress, Closed, etc.';
COMMENT ON COLUMN cases.progress IS 'DEPRECATED - Progress percentage (0-100), calculated by frontend';
COMMENT ON COLUMN cases.serial_number IS 'Serial number for display and filtering';
COMMENT ON COLUMN cases.part_number IS 'Part number for display and filtering';
COMMENT ON COLUMN cases.product_description IS 'Product description for display';
COMMENT ON COLUMN cases.subject IS 'Case subject/title for display';
COMMENT ON COLUMN cases.submitted_at IS 'Original case submission timestamp';
COMMENT ON COLUMN cases.case_data IS 'Complete case data from Salesforce as JSONB';
COMMENT ON COLUMN cases.synced_at IS 'Last synchronization timestamp from Salesforce';

-- ============================================================================
-- VERIFICATION
-- ============================================================================

-- Verify table creation
SELECT 
    'cases' as table_name,
    COUNT(*) as row_count,
    pg_size_pretty(pg_total_relation_size('cases')) as total_size
FROM cases;

-- List all indexes
SELECT 
    indexname,
    indexdef
FROM pg_indexes
WHERE tablename = 'cases'
ORDER BY indexname;



