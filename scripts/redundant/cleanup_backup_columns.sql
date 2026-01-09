-- ============================================================================
-- CLEANUP: Remove backup columns after verifying migration success
-- ============================================================================
-- Run this script ONLY after verifying that:
-- 1. All IDs are in the correct new format
-- 2. All foreign key relationships are intact
-- 3. Your application works correctly with the new IDs
-- ============================================================================

-- Remove backup columns
ALTER TABLE case_drafts DROP COLUMN IF EXISTS old_draft_id;
ALTER TABLE draft_attachments DROP COLUMN IF EXISTS old_attachment_id;
ALTER TABLE case_attachments DROP COLUMN IF EXISTS old_attachment_id;
ALTER TABLE case_comments DROP COLUMN IF EXISTS old_comment_id;

-- Verify cleanup
SELECT 'Backup columns removed successfully!' as status;

-- Show current columns
SELECT 
    table_name,
    column_name,
    data_type,
    character_maximum_length
FROM information_schema.columns
WHERE table_name IN ('case_drafts', 'draft_attachments', 'case_attachments', 'case_comments')
    AND column_name LIKE '%_id'
ORDER BY table_name, column_name;

