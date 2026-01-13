-- ============================================================================
-- DRAFT_ATTACHMENTS TABLE CREATION SCRIPT
-- ============================================================================
-- Purpose: Store attachments for draft cases before submission to Salesforce
-- Dependencies: Requires 'case_drafts' table to exist
-- ============================================================================

-- Drop table if exists (use with caution in production)
-- DROP TABLE IF EXISTS draft_attachments CASCADE;

-- ============================================================================
-- Function to generate draft attachment_id with prefix d_att_
-- ============================================================================
CREATE OR REPLACE FUNCTION generate_draft_attachment_id()
RETURNS varchar(14) AS $$
BEGIN
    RETURN 'd_att_' || lower(substring(replace(gen_random_uuid()::text, '-', ''), 1, 8));
END;
$$ LANGUAGE plpgsql VOLATILE;

-- ============================================================================
-- Create draft_attachments table
-- ============================================================================
CREATE TABLE draft_attachments (
    attachment_id VARCHAR(14) PRIMARY KEY DEFAULT generate_draft_attachment_id(),
    draft_id VARCHAR(7) NOT NULL,
    file_name VARCHAR(255) NOT NULL,
    content_type VARCHAR(100),
    s3_key VARCHAR(500) NOT NULL,
    meta JSONB,
    sync_status VARCHAR(20) NOT NULL DEFAULT 'uploaded',
    sync_error TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('UTC', NOW()),
    
    CONSTRAINT fk_draft_attachments_draft
        FOREIGN KEY (draft_id) REFERENCES case_drafts(draft_id) ON DELETE CASCADE,
    CONSTRAINT check_attachment_id_format
        CHECK (length(attachment_id) = 14 AND attachment_id ~ '^d_att_[0-9a-f]{8}$')
);

-- ============================================================================
-- INDEXES FOR PERFORMANCE
-- ============================================================================

-- Index for foreign key lookups (get all attachments for a draft)
CREATE INDEX idx_draft_attachments_draft_id ON draft_attachments(draft_id);

-- Index for filtering by sync status
CREATE INDEX idx_draft_attachments_sync_status ON draft_attachments(sync_status);

-- Index for sorting by creation time
CREATE INDEX idx_draft_attachments_created_at ON draft_attachments(created_at DESC);

-- Composite index for common query pattern (draft + creation time)
CREATE INDEX idx_draft_attachments_draft_created ON draft_attachments(draft_id, created_at DESC);

-- Composite index for sync operations (status + created time)
CREATE INDEX idx_draft_attachments_sync_created ON draft_attachments(sync_status, created_at);

-- Index for S3 key lookups (useful for cleanup operations)
CREATE INDEX idx_draft_attachments_s3_key ON draft_attachments(s3_key);

-- Index for filename searches
CREATE INDEX idx_draft_attachments_file_name ON draft_attachments(file_name);

-- GIN index for JSONB meta column (efficient JSONB queries)
CREATE INDEX idx_draft_attachments_meta ON draft_attachments USING GIN(meta);

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON TABLE draft_attachments IS 'Attachments for draft cases, stored in S3 before Salesforce sync';
COMMENT ON COLUMN draft_attachments.attachment_id IS 'Auto-generated draft attachment ID (e.g., d_att_a3f8e2c9)';
COMMENT ON COLUMN draft_attachments.draft_id IS 'Foreign key to case_drafts table';
COMMENT ON COLUMN draft_attachments.file_name IS 'Original filename of the attachment';
COMMENT ON COLUMN draft_attachments.content_type IS 'MIME type (e.g., image/png, application/pdf)';
COMMENT ON COLUMN draft_attachments.s3_key IS 'S3 object key/path in our bucket';
COMMENT ON COLUMN draft_attachments.meta IS 'Frontend metadata (UI section, custom fields, etc.) stored as JSON';
COMMENT ON COLUMN draft_attachments.sync_status IS 'Sync status: uploaded, syncing, synced, or sync_failed';
COMMENT ON COLUMN draft_attachments.sync_error IS 'Error message if sync failed';
COMMENT ON COLUMN draft_attachments.created_at IS 'Timestamp when attachment was uploaded';

-- Display success message
DO $$
BEGIN
    RAISE NOTICE '✓ draft_attachments table created with auto-generated attachment_id (d_att_xxxx)';
END $$;
