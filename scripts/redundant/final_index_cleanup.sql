-- ============================================================================
-- FINAL INDEX CLEANUP - Remove specific unwanted indexes
-- ============================================================================

-- Drop the created_at index explicitly
DROP INDEX IF EXISTS idx_case_drafts_created_at;

-- Drop salesforce_case_id index if it wasn't removed
DROP INDEX IF EXISTS idx_case_drafts_salesforce_case_id;

-- Verify final state
SELECT 
    indexname,
    indexdef
FROM pg_indexes
WHERE tablename = 'case_drafts'
ORDER BY indexname;

