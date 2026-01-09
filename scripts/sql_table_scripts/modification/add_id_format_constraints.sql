-- ============================================================================
-- ADD CONSTRAINTS FOR NEW UUID-BASED ID FORMATS
-- ============================================================================
-- Purpose: Add CHECK constraints to validate the new ID formats
-- This ensures data integrity for UUID-based IDs
-- ============================================================================

-- ============================================================================
-- 1. case_drafts.draft_id - Must be exactly 6 hex characters
-- ============================================================================

ALTER TABLE case_drafts
ADD CONSTRAINT check_draft_id_format
CHECK (
    LENGTH(draft_id) = 6 
    AND draft_id ~ '^[0-9A-Fa-f]{6}$'  -- Hex characters only
);

COMMENT ON CONSTRAINT check_draft_id_format ON case_drafts 
IS 'Ensures draft_id is exactly 6 hexadecimal characters (e.g., A3F8E2)';

-- ============================================================================
-- 2. draft_attachments.attachment_id - Must be att_ + 8 hex characters
-- ============================================================================

ALTER TABLE draft_attachments
ADD CONSTRAINT check_attachment_id_format
CHECK (
    LENGTH(attachment_id) = 12 
    AND attachment_id ~ '^att_[0-9a-f]{8}$'  -- att_ + 8 lowercase hex
);

COMMENT ON CONSTRAINT check_attachment_id_format ON draft_attachments 
IS 'Ensures attachment_id format: att_XXXXXXXX (8 hex chars)';

-- ============================================================================
-- 3. case_attachments.attachment_id - Must be att_ + 8 hex characters
-- ============================================================================

ALTER TABLE case_attachments
ADD CONSTRAINT check_attachment_id_format
CHECK (
    LENGTH(attachment_id) = 12 
    AND attachment_id ~ '^att_[0-9a-f]{8}$'  -- att_ + 8 lowercase hex
);

COMMENT ON CONSTRAINT check_attachment_id_format ON case_attachments 
IS 'Ensures attachment_id format: att_XXXXXXXX (8 hex chars)';

-- ============================================================================
-- 4. case_comments.comment_id - Must be cmt_ + 8 hex characters
-- ============================================================================

ALTER TABLE case_comments
ADD CONSTRAINT check_comment_id_format
CHECK (
    LENGTH(comment_id) = 12 
    AND comment_id ~ '^cmt_[0-9a-f]{8}$'  -- cmt_ + 8 lowercase hex
);

COMMENT ON CONSTRAINT check_comment_id_format ON case_comments 
IS 'Ensures comment_id format: cmt_XXXXXXXX (8 hex chars)';

-- ============================================================================
-- VERIFICATION
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '=================================================================';
    RAISE NOTICE 'ID FORMAT CONSTRAINTS ADDED SUCCESSFULLY';
    RAISE NOTICE '=================================================================';
    RAISE NOTICE 'Constraints:';
    RAISE NOTICE '  case_drafts.draft_id:              6 hex chars (e.g., A3F8E2)';
    RAISE NOTICE '  draft_attachments.attachment_id:   att_XXXXXXXX (12 chars)';
    RAISE NOTICE '  case_attachments.attachment_id:    att_XXXXXXXX (12 chars)';
    RAISE NOTICE '  case_comments.comment_id:          cmt_XXXXXXXX (12 chars)';
    RAISE NOTICE '=================================================================';
    RAISE NOTICE 'All IDs will be validated against UUID-based format.';
    RAISE NOTICE '=================================================================';
END $$;

-- List all constraints
SELECT 
    tc.table_name,
    tc.constraint_name,
    tc.constraint_type,
    cc.check_clause
FROM information_schema.table_constraints tc
LEFT JOIN information_schema.check_constraints cc
    ON tc.constraint_name = cc.constraint_name
WHERE tc.table_name IN ('case_drafts', 'draft_attachments', 'case_attachments', 'case_comments')
    AND tc.constraint_type = 'CHECK'
ORDER BY tc.table_name, tc.constraint_name;

-- Test constraints with sample data (will fail if format is wrong)
-- Uncomment to test:
-- INSERT INTO case_drafts (draft_id, user_id) VALUES ('INVALID', 'test'); -- Should fail
-- INSERT INTO case_comments (comment_id, case_id, body, created_by) VALUES ('bad_format', 'test', 'test', 'test'); -- Should fail

-- End of constraints script

