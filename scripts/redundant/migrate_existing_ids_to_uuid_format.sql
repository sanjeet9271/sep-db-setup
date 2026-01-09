-- ============================================================================
-- MIGRATE EXISTING IDs TO NEW UUID FORMAT
-- ============================================================================
-- Purpose: Update existing records to use new UUID-based ID format
-- This script safely updates IDs while preserving foreign key relationships
-- 
-- Tables to update:
--   - case_drafts: 6 char old format -> 6 char hex UUID format
--   - draft_attachments: 6 char old format -> att_XXXXXXXX (12 char)
--   - case_attachments: att_XXXX (10 char) -> att_XXXXXXXX (12 char)
--   - case_comments: cmt_XXXX (10 char) -> cmt_XXXXXXXX (12 char)
-- ============================================================================

-- ============================================================================
-- STEP 0: Drop CHECK constraints that validate old ID formats
-- ============================================================================

-- Drop old format constraints if they exist
ALTER TABLE case_attachments DROP CONSTRAINT IF EXISTS check_attachment_id_format;
ALTER TABLE draft_attachments DROP CONSTRAINT IF EXISTS check_attachment_id_format;
ALTER TABLE case_comments DROP CONSTRAINT IF EXISTS check_comment_id_format;
ALTER TABLE case_drafts DROP CONSTRAINT IF EXISTS check_draft_id_format;

-- ============================================================================
-- SAFETY CHECK: Create backup columns first
-- ============================================================================

-- Add backup columns to preserve old IDs
ALTER TABLE case_drafts ADD COLUMN IF NOT EXISTS old_draft_id varchar(6);
ALTER TABLE draft_attachments ADD COLUMN IF NOT EXISTS old_attachment_id varchar(20);
ALTER TABLE case_attachments ADD COLUMN IF NOT EXISTS old_attachment_id varchar(20);
ALTER TABLE case_comments ADD COLUMN IF NOT EXISTS old_comment_id varchar(20);

-- Save current IDs to backup columns
UPDATE case_drafts SET old_draft_id = draft_id WHERE old_draft_id IS NULL;
UPDATE draft_attachments SET old_attachment_id = attachment_id WHERE old_attachment_id IS NULL;
UPDATE case_attachments SET old_attachment_id = attachment_id WHERE old_attachment_id IS NULL;
UPDATE case_comments SET old_comment_id = comment_id WHERE old_comment_id IS NULL;

-- ============================================================================
-- STEP 1: Update case_drafts and cascade to draft_attachments
-- ============================================================================
-- Note: draft_attachments has FK to case_drafts, so we handle this carefully
-- ============================================================================

-- Create temporary mapping table for case_drafts
CREATE TEMP TABLE IF NOT EXISTS draft_id_mapping (
    old_id varchar(6),
    new_id varchar(6)
);

-- Generate new IDs for all existing case_drafts
INSERT INTO draft_id_mapping (old_id, new_id)
SELECT 
    draft_id as old_id,
    generate_draft_id() as new_id
FROM case_drafts;

-- Update draft_attachments.draft_id to match new case_drafts IDs
UPDATE draft_attachments da
SET draft_id = m.new_id
FROM draft_id_mapping m
WHERE da.draft_id = m.old_id;

-- Update case_drafts with new IDs
UPDATE case_drafts cd
SET draft_id = m.new_id
FROM draft_id_mapping m
WHERE cd.draft_id = m.old_id;

-- ============================================================================
-- STEP 2: Update draft_attachments.attachment_id
-- ============================================================================
-- Now update the attachment_id itself (not the FK to drafts)
-- ============================================================================

UPDATE draft_attachments
SET attachment_id = generate_draft_attachment_id()
WHERE length(attachment_id) != 12;  -- Only update old format

-- ============================================================================
-- STEP 3: Update case_attachments.attachment_id
-- ============================================================================
-- These use att_XXXX format (10 chars) -> att_XXXXXXXX (12 chars)
-- ============================================================================

UPDATE case_attachments
SET attachment_id = generate_case_attachment_id()
WHERE length(attachment_id) < 12;  -- Update old format (att_XXXX)

-- ============================================================================
-- STEP 4: Update case_comments.comment_id
-- ============================================================================
-- These use cmt_XXXX format (10 chars) -> cmt_XXXXXXXX (12 chars)
-- ============================================================================

UPDATE case_comments
SET comment_id = generate_comment_id()
WHERE length(comment_id) < 12;  -- Update old format (cmt_XXXX)

-- ============================================================================
-- VERIFICATION
-- ============================================================================

DO $$
DECLARE
    draft_count INTEGER;
    draft_att_count INTEGER;
    case_att_count INTEGER;
    comment_count INTEGER;
BEGIN
    -- Count updated records
    SELECT COUNT(*) INTO draft_count FROM case_drafts WHERE length(draft_id) = 6;
    SELECT COUNT(*) INTO draft_att_count FROM draft_attachments WHERE length(attachment_id) = 12;
    SELECT COUNT(*) INTO case_att_count FROM case_attachments WHERE length(attachment_id) = 12;
    SELECT COUNT(*) INTO comment_count FROM case_comments WHERE length(comment_id) = 12;
    
    RAISE NOTICE '=================================================================';
    RAISE NOTICE 'ID MIGRATION COMPLETED';
    RAISE NOTICE '=================================================================';
    RAISE NOTICE 'Records Updated:';
    RAISE NOTICE '  case_drafts:       % records (6 char hex UUID)', draft_count;
    RAISE NOTICE '  draft_attachments: % records (att_XXXXXXXX)', draft_att_count;
    RAISE NOTICE '  case_attachments:  % records (att_XXXXXXXX)', case_att_count;
    RAISE NOTICE '  case_comments:     % records (cmt_XXXXXXXX)', comment_count;
    RAISE NOTICE '=================================================================';
    RAISE NOTICE 'Old IDs preserved in backup columns:';
    RAISE NOTICE '  - old_draft_id';
    RAISE NOTICE '  - old_attachment_id';
    RAISE NOTICE '  - old_comment_id';
    RAISE NOTICE '=================================================================';
END $$;

-- Show sample of updated IDs
SELECT 'case_drafts samples:' as info;
SELECT draft_id, old_draft_id FROM case_drafts LIMIT 5;

SELECT 'draft_attachments samples:' as info;
SELECT attachment_id, old_attachment_id, draft_id FROM draft_attachments LIMIT 5;

SELECT 'case_attachments samples:' as info;
SELECT attachment_id, old_attachment_id FROM case_attachments LIMIT 5;

SELECT 'case_comments samples:' as info;
SELECT comment_id, old_comment_id FROM case_comments LIMIT 5;

-- ============================================================================
-- CLEANUP (OPTIONAL - UNCOMMENT AFTER VERIFICATION)
-- ============================================================================
-- After verifying the migration was successful, you can remove backup columns:
-- 
-- ALTER TABLE case_drafts DROP COLUMN old_draft_id;
-- ALTER TABLE draft_attachments DROP COLUMN old_attachment_id;
-- ALTER TABLE case_attachments DROP COLUMN old_attachment_id;
-- ALTER TABLE case_comments DROP COLUMN old_comment_id;
-- ============================================================================

-- End of migration script

