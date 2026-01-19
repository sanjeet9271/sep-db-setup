-- ============================================================================
-- REMOVE BACKUP COLUMNS FROM CASE_DRAFTS TABLE
-- ============================================================================
-- Purpose: Clean up old backup columns that are no longer needed
-- Date: 2026-01-19
-- Status: ✅ EXECUTED SUCCESSFULLY
-- ============================================================================

-- Drop old_draft_id column
ALTER TABLE case_drafts 
DROP COLUMN IF EXISTS old_draft_id;

-- Drop old_draft_id_v2 column
ALTER TABLE case_drafts 
DROP COLUMN IF EXISTS old_draft_id_v2;

-- ============================================================================
-- RESULT: case_drafts now has 14 columns (removed 2 backup columns)
-- ============================================================================
