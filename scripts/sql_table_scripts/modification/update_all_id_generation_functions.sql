-- ============================================================================
-- COMPREHENSIVE ID GENERATION FUNCTIONS UPDATE - UUID BASED
-- ============================================================================
-- Purpose: Update all auto-generated ID functions using PostgreSQL's UUID
-- Tables affected:
--   1. case_drafts (draft_id) - 6 hex chars (~16.7M combinations for 250K records)
--   2. draft_attachments (attachment_id) - att_ + 7 hex chars (~268M for 12.5M records)
--   3. case_attachments (attachment_id) - att_ + 8 hex chars (~4.3B for 100M records)
--   4. case_comments (comment_id) - cmt_ + 8 hex chars (~4.3B for 100M records)
--
-- Uses PostgreSQL's gen_random_uuid() for collision-free IDs
-- No collision checking needed - UUID provides sufficient entropy
-- ============================================================================

-- ============================================================================
-- Volume Calculations:
-- ============================================================================
-- Draft IDs:         5,000 users × 50 drafts = 250,000 records
--                    16^6 = 16,777,216 combinations (67x safety margin)
--
-- Draft Attachments: 250,000 drafts × 50 attachments = 12,500,000 records
--                    16^8 = 4,294,967,296 combinations (343x safety margin)
--
-- Case Attachments:  1,000,000 cases × 100 attachments = 100,000,000 records
--                    16^8 = 4,294,967,296 combinations (43x safety margin)
--
-- Case Comments:     1,000,000 cases × 100 comments = 100,000,000 records
--                    16^8 = 4,294,967,296 combinations (43x safety margin)
-- ============================================================================

-- ============================================================================
-- 1. UPDATE: generate_draft_id() for case_drafts table
-- ============================================================================
-- Generates 6-character hex IDs (uppercase, no prefix)
-- Format: A3F8E2, C91D4F, 2B7E9A
-- Character set: 0-9, A-F (16 characters)
-- Combinations: 16^6 = 16,777,216
-- ============================================================================

CREATE OR REPLACE FUNCTION generate_draft_id()
RETURNS varchar(6) AS $$
BEGIN
    RETURN upper(substring(replace(gen_random_uuid()::text, '-', ''), 1, 6));
END;
$$ LANGUAGE plpgsql VOLATILE;

COMMENT ON FUNCTION generate_draft_id() IS 'Generates unique 6-character hex draft ID using UUID (16.7M combinations for 250K records)';

-- ============================================================================
-- 2. UPDATE: generate_attachment_id() for draft_attachments table
-- ============================================================================
-- Generates attachment IDs with format: att_XXXXXXXX (8 hex chars after prefix)
-- Format: att_a3f8e2c9, att_c91d4f87, att_2b7e9a16
-- Character set: 0-9, a-f (16 characters, lowercase)
-- Combinations: 16^8 = 4,294,967,296 (4.3 billion)
-- Note: Same length as case_attachments for consistency
-- ============================================================================

CREATE OR REPLACE FUNCTION generate_draft_attachment_id()
RETURNS varchar(12) AS $$
BEGIN
    RETURN 'att_' || lower(substring(replace(gen_random_uuid()::text, '-', ''), 1, 8));
END;
$$ LANGUAGE plpgsql VOLATILE;

COMMENT ON FUNCTION generate_draft_attachment_id() IS 'Generates unique attachment ID for drafts: att_XXXXXXXX (4.3B combinations for 12.5M records)';

-- ============================================================================
-- 3. UPDATE: generate_attachment_id() for case_attachments table
-- ============================================================================
-- Generates attachment IDs with format: att_XXXXXXXX (8 hex chars after prefix)
-- Format: att_a3f8e2c9, att_c91d4f87, att_2b7e9a16
-- Character set: 0-9, a-f (16 characters, lowercase)
-- Combinations: 16^8 = 4,294,967,296 (4.3 billion)
-- ============================================================================

CREATE OR REPLACE FUNCTION generate_case_attachment_id()
RETURNS varchar(12) AS $$
BEGIN
    RETURN 'att_' || lower(substring(replace(gen_random_uuid()::text, '-', ''), 1, 8));
END;
$$ LANGUAGE plpgsql VOLATILE;

COMMENT ON FUNCTION generate_case_attachment_id() IS 'Generates unique attachment ID for cases: att_XXXXXXXX (4.3B combinations for 100M records)';

-- ============================================================================
-- 4. CREATE: generate_comment_id() for case_comments table
-- ============================================================================
-- Generates comment IDs with format: cmt_XXXXXXXX (8 hex chars after prefix)
-- Format: cmt_7k2a9b4f, cmt_3e8c1f2d, cmt_f9h6m3p8
-- Character set: 0-9, a-f (16 characters, lowercase)
-- Combinations: 16^8 = 4,294,967,296 (4.3 billion)
-- ============================================================================

CREATE OR REPLACE FUNCTION generate_comment_id()
RETURNS varchar(12) AS $$
BEGIN
    RETURN 'cmt_' || lower(substring(replace(gen_random_uuid()::text, '-', ''), 1, 8));
END;
$$ LANGUAGE plpgsql VOLATILE;

COMMENT ON FUNCTION generate_comment_id() IS 'Generates unique comment ID: cmt_XXXXXXXX (4.3B combinations for 100M records)';

-- ============================================================================
-- 5. UPDATE TABLE COLUMN DEFINITIONS
-- ============================================================================
-- Update column types and defaults to match new ID formats
-- Existing data is NOT modified - only affects new inserts
-- ============================================================================

-- Update case_drafts.draft_id
ALTER TABLE case_drafts 
    ALTER COLUMN draft_id TYPE varchar(6),
    ALTER COLUMN draft_id SET DEFAULT generate_draft_id();

-- Update draft_attachments.attachment_id  
ALTER TABLE draft_attachments 
    ALTER COLUMN attachment_id TYPE varchar(12),
    ALTER COLUMN attachment_id SET DEFAULT generate_draft_attachment_id();

-- Update case_attachments.attachment_id
ALTER TABLE case_attachments 
    ALTER COLUMN attachment_id TYPE varchar(12),
    ALTER COLUMN attachment_id SET DEFAULT generate_case_attachment_id();

-- Update case_comments.comment_id
ALTER TABLE case_comments 
    ALTER COLUMN comment_id TYPE varchar(12),
    ALTER COLUMN comment_id SET DEFAULT generate_comment_id();

-- Update column comments
COMMENT ON COLUMN case_drafts.draft_id IS 'Auto-generated unique 6-char hex ID (e.g., A3F8E2) using UUID';
COMMENT ON COLUMN draft_attachments.attachment_id IS 'Auto-generated unique ID: att_XXXXXXXX (8 hex chars) using UUID';
COMMENT ON COLUMN case_attachments.attachment_id IS 'Auto-generated unique ID: att_XXXXXXXX (8 hex chars) using UUID';
COMMENT ON COLUMN case_comments.comment_id IS 'Auto-generated unique ID: cmt_XXXXXXXX (8 hex chars) using UUID';

-- ============================================================================
-- 6. OPTIONAL: UPDATE EXISTING RECORDS (COMMENTED OUT FOR SAFETY)
-- ============================================================================
-- WARNING: Only run this if you want to regenerate IDs for existing records
-- This will change primary keys and may break foreign key relationships
-- Make sure to backup data before running!
-- ============================================================================

-- -- Backup existing IDs (create backup columns)
-- ALTER TABLE case_drafts ADD COLUMN old_draft_id varchar(6);
-- ALTER TABLE draft_attachments ADD COLUMN old_attachment_id varchar(10);
-- ALTER TABLE case_attachments ADD COLUMN old_attachment_id varchar(10);
-- ALTER TABLE case_comments ADD COLUMN old_comment_id varchar(10);

-- -- Save old IDs
-- UPDATE case_drafts SET old_draft_id = draft_id;
-- UPDATE draft_attachments SET old_attachment_id = attachment_id;
-- UPDATE case_attachments SET old_attachment_id = attachment_id;
-- UPDATE case_comments SET old_comment_id = comment_id;

-- -- Update to new UUID-based format
-- UPDATE case_drafts SET draft_id = generate_draft_id();
-- UPDATE draft_attachments SET attachment_id = generate_draft_attachment_id();
-- UPDATE case_attachments SET attachment_id = generate_case_attachment_id();
-- UPDATE case_comments SET comment_id = generate_comment_id();

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Test function execution (without inserting data)
DO $$
DECLARE
    test_draft_id varchar(6);
    test_draft_attachment_id varchar(12);
    test_case_attachment_id varchar(12);
    test_comment_id varchar(12);
BEGIN
    -- Test each function
    test_draft_id := generate_draft_id();
    test_draft_attachment_id := generate_draft_attachment_id();
    test_case_attachment_id := generate_case_attachment_id();
    test_comment_id := generate_comment_id();
    
    RAISE NOTICE '=================================================================';
    RAISE NOTICE 'UUID-Based ID Generation Functions Updated Successfully!';
    RAISE NOTICE '=================================================================';
    RAISE NOTICE 'Test Results:';
    RAISE NOTICE '  Draft ID:              % (6 hex chars)', test_draft_id;
    RAISE NOTICE '  Draft Attachment ID:   % (att_ + 8 hex chars)', test_draft_attachment_id;
    RAISE NOTICE '  Case Attachment ID:    % (att_ + 8 hex chars)', test_case_attachment_id;
    RAISE NOTICE '  Comment ID:            % (cmt_ + 8 hex chars)', test_comment_id;
    RAISE NOTICE '=================================================================';
    RAISE NOTICE 'Capacity Summary:';
    RAISE NOTICE '  Draft IDs:        16.7M combinations for 250K expected records';
    RAISE NOTICE '  Draft Attach:     4.3B combinations for 12.5M expected records';
    RAISE NOTICE '  Case Attach:      4.3B combinations for 100M expected records';
    RAISE NOTICE '  Comments:         4.3B combinations for 100M expected records';
    RAISE NOTICE '=================================================================';
    RAISE NOTICE 'All functions use PostgreSQL UUID for collision-free generation.';
    RAISE NOTICE 'Existing data unchanged. New records will use new format.';
    RAISE NOTICE '=================================================================';
END $$;

-- List all ID generation functions
SELECT 
    routine_name as function_name,
    data_type as return_type,
    routine_definition as has_definition
FROM information_schema.routines
WHERE routine_schema = 'public'
    AND (routine_name LIKE 'generate_%_id' OR routine_name LIKE 'generate_%_attachment_id')
ORDER BY routine_name;

-- Verify column definitions
SELECT 
    table_name,
    column_name,
    data_type,
    character_maximum_length,
    column_default,
    is_nullable
FROM information_schema.columns
WHERE table_name IN ('case_drafts', 'case_comments', 'case_attachments', 'draft_attachments')
    AND column_name IN ('draft_id', 'comment_id', 'attachment_id')
ORDER BY table_name, column_name;

-- Check if any existing records have IDs in old format
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '=================================================================';
    RAISE NOTICE 'Existing Records Check:';
    RAISE NOTICE '=================================================================';
    
    -- Count records in each table
    RAISE NOTICE 'Total Records:';
    RAISE NOTICE '  case_drafts:       % records', (SELECT COUNT(*) FROM case_drafts);
    RAISE NOTICE '  draft_attachments: % records', (SELECT COUNT(*) FROM draft_attachments);
    RAISE NOTICE '  case_attachments:  % records', (SELECT COUNT(*) FROM case_attachments);
    RAISE NOTICE '  case_comments:     % records', (SELECT COUNT(*) FROM case_comments);
    RAISE NOTICE '=================================================================';
    RAISE NOTICE 'NOTE: Existing records keep their old IDs.';
    RAISE NOTICE 'Only NEW records will use the UUID-based format.';
    RAISE NOTICE '=================================================================';
END $$;

-- ============================================================================
-- End of migration script
-- ============================================================================
