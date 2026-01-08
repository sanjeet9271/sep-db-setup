-- ============================================================================
-- CASE_COMMENTS TABLE CREATION SCRIPT
-- ============================================================================
-- Purpose: Store comments for cases with sync status tracking
-- Dependencies: Requires 'cases' table to exist
-- ============================================================================

-- Drop table if exists (use with caution in production)
-- DROP TABLE IF EXISTS case_comments CASCADE;

-- Create case_comments table
CREATE TABLE case_comments (
    comment_id VARCHAR(10) PRIMARY KEY,            -- Auto-generated (e.g., cmt_x7k2)
    case_id VARCHAR(18) NOT NULL,                  -- References Salesforce Case ID
    body TEXT NOT NULL,                            -- Comment text (max 5000 chars)
    created_by VARCHAR(100) NOT NULL,              -- User ID who created the comment
    sync_status VARCHAR(20) NOT NULL DEFAULT 'pending',  -- pending|syncing|synced|sync_failed
    sf_comment_id VARCHAR(18),                     -- SF CaseComment ID after sync
    sync_error TEXT,                               -- Error message on sync failure
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), -- Creation timestamp
    
    CONSTRAINT fk_case_comments_case 
        FOREIGN KEY (case_id) REFERENCES cases(case_id) ON DELETE CASCADE,
    
    CONSTRAINT chk_comment_length CHECK (LENGTH(body) <= 5000)
);

-- ============================================================================
-- INDEXES FOR PERFORMANCE
-- ============================================================================

-- Index for foreign key lookups (get all comments for a case)
CREATE INDEX idx_case_comments_case_id ON case_comments(case_id);

-- Index for filtering by sync status
CREATE INDEX idx_case_comments_sync_status ON case_comments(sync_status);

-- Index for filtering by creator
CREATE INDEX idx_case_comments_created_by ON case_comments(created_by);

-- Index for sorting by creation time
CREATE INDEX idx_case_comments_created_at ON case_comments(created_at DESC);

-- Composite index for common query pattern (case + creation time)
CREATE INDEX idx_case_comments_case_created ON case_comments(case_id, created_at DESC);

-- Composite index for sync operations (status + created time)
CREATE INDEX idx_case_comments_sync_created ON case_comments(sync_status, created_at);

-- Index for Salesforce comment ID lookups
CREATE INDEX idx_case_comments_sf_id ON case_comments(sf_comment_id) 
    WHERE sf_comment_id IS NOT NULL;

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON TABLE case_comments IS 'Comments associated with cases, tracking sync status to Salesforce';
COMMENT ON COLUMN case_comments.comment_id IS 'Auto-generated comment ID (e.g., cmt_x7k2)';
COMMENT ON COLUMN case_comments.case_id IS 'Foreign key to cases table';
COMMENT ON COLUMN case_comments.body IS 'Comment text content (max 5000 characters)';
COMMENT ON COLUMN case_comments.created_by IS 'User ID of comment creator';
COMMENT ON COLUMN case_comments.sync_status IS 'Sync status: pending, syncing, synced, or sync_failed';
COMMENT ON COLUMN case_comments.sf_comment_id IS 'Salesforce CaseComment ID after successful sync';
COMMENT ON COLUMN case_comments.sync_error IS 'Error message if sync failed';
COMMENT ON COLUMN case_comments.created_at IS 'Timestamp when comment was created';

-- ============================================================================
-- VERIFICATION
-- ============================================================================

-- Verify table creation
SELECT 
    'case_comments' as table_name,
    COUNT(*) as row_count,
    pg_size_pretty(pg_total_relation_size('case_comments')) as total_size
FROM case_comments;

-- List all indexes
SELECT 
    indexname,
    indexdef
FROM pg_indexes
WHERE tablename = 'case_comments'
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
    AND tc.table_name = 'case_comments';









