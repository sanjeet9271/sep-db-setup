-- ============================================================================
-- CASE_DRAFTS INDEX CLEANUP SCRIPT
-- ============================================================================
-- Purpose: Remove unnecessary indexes and keep only essential ones
-- Table: case_drafts
-- Date: January 8, 2026
-- ============================================================================

-- ============================================================================
-- STEP 1: DROP UNNECESSARY INDEXES
-- ============================================================================

-- Drop account-related indexes (removing account_id dependency)
DROP INDEX IF EXISTS idx_case_drafts_account_id CASCADE;
DROP INDEX IF EXISTS idx_case_drafts_account_status CASCADE;

-- Drop timestamp indexes (not critical for performance)
DROP INDEX IF EXISTS idx_case_drafts_created_at CASCADE;
DROP INDEX IF EXISTS idx_case_drafts_updated_at CASCADE;

-- Drop Salesforce case ID index (rarely queried)
DROP INDEX IF EXISTS idx_case_drafts_sf_case_id CASCADE;
DROP INDEX IF EXISTS idx_case_drafts_salesforce_case_id CASCADE;

-- Drop JSONB GIN index (expensive to maintain, query-specific)
DROP INDEX IF EXISTS idx_case_drafts_case_data CASCADE;

-- ============================================================================
-- STEP 2: VERIFY ESSENTIAL INDEXES EXIST (KEEP THESE)
-- ============================================================================

-- These indexes should already exist from table creation:
-- 1. idx_case_drafts_user_id (user_id) - Filter by user
-- 2. idx_case_drafts_user_status (user_id, submission_status) - User's active drafts
-- 3. idx_case_drafts_submission_status (submission_status) - Background job queries
-- 4. idx_case_drafts_case_type (case_type) - Filter by case type

-- ============================================================================
-- STEP 3: CREATE MISSING INDEXES
-- ============================================================================

-- Add index for serial number filtering
CREATE INDEX IF NOT EXISTS idx_case_drafts_serial_number 
    ON case_drafts(serial_number);

-- Add index for part number filtering
CREATE INDEX IF NOT EXISTS idx_case_drafts_part_number 
    ON case_drafts(part_number);

-- Add composite index for user + status (if not exists)
CREATE INDEX IF NOT EXISTS idx_case_drafts_user_status 
    ON case_drafts(user_id, submission_status);

-- ============================================================================
-- VERIFICATION QUERY
-- ============================================================================

-- List all remaining indexes on case_drafts table
SELECT 
    indexname,
    indexdef
FROM pg_indexes
WHERE tablename = 'case_drafts'
ORDER BY indexname;

-- ============================================================================
-- SUMMARY OF REMAINING INDEXES
-- ============================================================================
-- 1. case_drafts_pkey (PRIMARY KEY on draft_id)
-- 2. idx_case_drafts_user_id (user_id)
-- 3. idx_case_drafts_user_status (user_id, submission_status)
-- 4. idx_case_drafts_submission_status (submission_status)
-- 5. idx_case_drafts_case_type (case_type)
-- 6. idx_case_drafts_serial_number (serial_number)
-- ============================================================================

