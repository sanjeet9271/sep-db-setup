-- ============================================================================
-- CASE_ATTACHMENTS TABLE CREATION SCRIPT
-- ============================================================================
-- Purpose: Store attachments for cases with S3 and Salesforce sync tracking
-- Dependencies: Requires 'cases' table to exist
-- ============================================================================

-- Drop table if exists (use with caution in production)
DROP TABLE IF EXISTS case_attachments CASCADE;

-- ============================================================================
-- Function to generate attachment_id with prefix att_
-- ============================================================================
CREATE OR REPLACE FUNCTION generate_attachment_id()
RETURNS varchar(10) AS $$
DECLARE
    chars TEXT := 'abcdefghjkmnpqrstuvwxyz23456789'; -- Lowercase + exclude confusing chars
    result TEXT := 'att_';
    i INTEGER;
BEGIN
    FOR i IN 1..4 LOOP
        result := result || substr(chars, floor(random() * length(chars) + 1)::int, 1);
    END LOOP;
    RETURN result;
END;
$$ LANGUAGE plpgsql VOLATILE;

-- ============================================================================
-- Create case_attachments table
-- ============================================================================
CREATE TABLE case_attachments (
    attachment_id VARCHAR(10) PRIMARY KEY DEFAULT generate_attachment_id(),
    case_id VARCHAR(18) NOT NULL,
    file_name VARCHAR(255) NOT NULL,
    content_type VARCHAR(100),
    s3_key VARCHAR(500) NOT NULL,
    sync_status VARCHAR(20) DEFAULT 'pending',
    sf_attachment_id VARCHAR(18),
    sync_error TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- CONSTRAINTS
-- ============================================================================

-- CHECK constraint for attachment_id format (att_ + 4 characters)
ALTER TABLE case_attachments
ADD CONSTRAINT check_attachment_id_format
CHECK (
    LENGTH(attachment_id) = 8 
    AND attachment_id LIKE 'att_%'
    AND LENGTH(SUBSTRING(attachment_id FROM 5)) = 4
);

-- CHECK constraint for sync_status
ALTER TABLE case_attachments
ADD CONSTRAINT check_attachment_sync_status
CHECK (sync_status IN ('pending', 'syncing', 'synced', 'sync_failed'));

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

COMMENT ON TABLE case_attachments IS 'File attachments to be synced to Salesforce cases';
COMMENT ON COLUMN case_attachments.attachment_id IS 'Auto-generated attachment ID with format att_<4 chars> (e.g., att_c8m4)';
COMMENT ON COLUMN case_attachments.case_id IS 'References Salesforce Case ID (18 chars)';
COMMENT ON COLUMN case_attachments.file_name IS 'Original file name';
COMMENT ON COLUMN case_attachments.content_type IS 'MIME type (e.g., image/png, application/pdf)';
COMMENT ON COLUMN case_attachments.s3_key IS 'S3 path in our bucket (max 500 chars)';
COMMENT ON COLUMN case_attachments.sync_status IS 'Sync status: pending|syncing|synced|sync_failed';
COMMENT ON COLUMN case_attachments.sf_attachment_id IS 'Salesforce Cloud_Attachment__c ID after successful sync';
COMMENT ON COLUMN case_attachments.sync_error IS 'Error message on sync failure';
COMMENT ON COLUMN case_attachments.created_at IS 'Timestamp when attachment was created';

-- Display success message
DO $$
BEGIN
    RAISE NOTICE '✓ case_attachments table created with auto-generated attachment_id (att_xxxx)';
END $$;
