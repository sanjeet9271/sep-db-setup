-- ============================================================================
-- CASE_ATTACHMENTS TABLE CREATION SCRIPT
-- ============================================================================
-- Purpose: Store attachments for cases with S3 and Salesforce sync tracking
-- Dependencies: Requires 'cases' table to exist
-- ============================================================================

-- Drop table if exists (use with caution in production)
-- DROP TABLE IF EXISTS case_attachments CASCADE;

-- Create case_attachments table
CREATE TABLE case_attachments (
    attachment_id VARCHAR(10) PRIMARY KEY,         -- Auto-generated (e.g., att_c8m4)
    case_id VARCHAR(18) NOT NULL,                  -- References Salesforce Case ID
    file_name VARCHAR(255) NOT NULL,               -- Original filename
    content_type VARCHAR(100),                     -- MIME type (e.g., image/png)
    s3_key VARCHAR(500) NOT NULL,                  -- S3 path in our bucket
    sync_status VARCHAR(20) NOT NULL DEFAULT 'pending',  -- pending|syncing|synced|sync_failed
    sf_attachment_id VARCHAR(18),                  -- SF Cloud_Attachment__c ID after sync
    sync_error TEXT,                               -- Error message on sync failure
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), -- Creation timestamp
    
    CONSTRAINT fk_case_attachments_case 
        FOREIGN KEY (case_id) REFERENCES cases(case_id) ON DELETE CASCADE
);

-- ============================================================================
-- INDEXES FOR PERFORMANCE
-- ============================================================================

-- Index for foreign key lookups (get all attachments for a case)
CREATE INDEX idx_case_attachments_case_id ON case_attachments(case_id);

-- Index for filtering by sync status
CREATE INDEX idx_case_attachments_sync_status ON case_attachments(sync_status);

-- Index for sorting by creation time
CREATE INDEX idx_case_attachments_created_at ON case_attachments(created_at DESC);

-- Composite index for common query pattern (case + creation time)
CREATE INDEX idx_case_attachments_case_created ON case_attachments(case_id, created_at DESC);

-- Composite index for sync operations (status + created time)
CREATE INDEX idx_case_attachments_sync_created ON case_attachments(sync_status, created_at);

-- Index for S3 key lookups (useful for cleanup operations)
CREATE INDEX idx_case_attachments_s3_key ON case_attachments(s3_key);

-- Index for Salesforce attachment ID lookups
CREATE INDEX idx_case_attachments_sf_id ON case_attachments(sf_attachment_id) 
    WHERE sf_attachment_id IS NOT NULL;

-- Index for filename searches
CREATE INDEX idx_case_attachments_file_name ON case_attachments(file_name);

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON TABLE case_attachments IS 'Attachments associated with cases, stored in S3 and synced to Salesforce';
COMMENT ON COLUMN case_attachments.attachment_id IS 'Auto-generated attachment ID (e.g., att_c8m4)';
COMMENT ON COLUMN case_attachments.case_id IS 'Foreign key to cases table';
COMMENT ON COLUMN case_attachments.file_name IS 'Original filename of the attachment';
COMMENT ON COLUMN case_attachments.content_type IS 'MIME type (e.g., image/png, application/pdf)';
COMMENT ON COLUMN case_attachments.s3_key IS 'S3 object key/path in our bucket';
COMMENT ON COLUMN case_attachments.sync_status IS 'Sync status: pending, syncing, synced, or sync_failed';
COMMENT ON COLUMN case_attachments.sf_attachment_id IS 'Salesforce Cloud_Attachment__c ID after successful sync';
COMMENT ON COLUMN case_attachments.sync_error IS 'Error message if sync failed';
COMMENT ON COLUMN case_attachments.created_at IS 'Timestamp when attachment was uploaded';

-- ============================================================================
-- VERIFICATION
-- ============================================================================

-- Verify table creation
SELECT 
    'case_attachments' as table_name,
    COUNT(*) as row_count,
    pg_size_pretty(pg_total_relation_size('case_attachments')) as total_size
FROM case_attachments;

-- List all indexes
SELECT 
    indexname,
    indexdef
FROM pg_indexes
WHERE tablename = 'case_attachments'
ORDER BY indexname;

-- Verify foreign key constraint
SELECT
    tc.constraint_name,
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
    AND tc.table_name = 'case_attachments';









