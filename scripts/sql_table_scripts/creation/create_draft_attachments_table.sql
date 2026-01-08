-- ============================================================================
-- DRAFT_ATTACHMENTS TABLE CREATION SCRIPT
-- ============================================================================
-- Purpose: Store attachments for draft cases before submission to Salesforce
-- Dependencies: Requires 'case_drafts' table to exist
-- ============================================================================

-- Drop table if exists (use with caution in production)
-- DROP TABLE IF EXISTS draft_attachments CASCADE;

-- Create draft_attachments table
CREATE TABLE draft_attachments (
    attachment_id VARCHAR(10) PRIMARY KEY,         -- Auto-generated (e.g., att_x7k2)
    draft_id VARCHAR(6) NOT NULL,                  -- References case_drafts
    file_name VARCHAR(255) NOT NULL,               -- Original filename
    content_type VARCHAR(100),                     -- MIME type (e.g., image/png)
    s3_key VARCHAR(500) NOT NULL,                  -- S3 path in our bucket
    sync_status VARCHAR(20) NOT NULL DEFAULT 'uploaded',  -- uploaded|syncing|synced|sync_failed
    sync_error TEXT,                               -- Error on sync failure
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), -- Creation timestamp
    
    CONSTRAINT fk_draft_attachments_draft
        FOREIGN KEY (draft_id) REFERENCES case_drafts(draft_id) ON DELETE CASCADE
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

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON TABLE draft_attachments IS 'Attachments for draft cases, stored in S3 before Salesforce sync';
COMMENT ON COLUMN draft_attachments.attachment_id IS 'Auto-generated attachment ID (e.g., att_x7k2)';
COMMENT ON COLUMN draft_attachments.draft_id IS 'Foreign key to case_drafts table';
COMMENT ON COLUMN draft_attachments.file_name IS 'Original filename of the attachment';
COMMENT ON COLUMN draft_attachments.content_type IS 'MIME type (e.g., image/png, application/pdf)';
COMMENT ON COLUMN draft_attachments.s3_key IS 'S3 object key/path in our bucket';
COMMENT ON COLUMN draft_attachments.sync_status IS 'Sync status: uploaded, syncing, synced, or sync_failed';
COMMENT ON COLUMN draft_attachments.sync_error IS 'Error message if sync failed';
COMMENT ON COLUMN draft_attachments.created_at IS 'Timestamp when attachment was uploaded';






