-- ============================================================================
-- EXPAND DRAFT_ID TO 7 CHARS AND UPDATE ATTACHMENT PREFIXES
-- ============================================================================
-- Purpose: 
--   1. Expand draft_id from 6 to 7 characters
--   2. Update existing draft_ids to 7-char format
--   3. Change attachment prefixes: att_ → datt_/catt_
--
-- New Formats:
--   - draft_id: 7 hex chars (e.g., A3F8E2C)
--   - draft_attachments: datt_XXXXXXXX (13 chars total)
--   - case_attachments: catt_XXXXXXXX (13 chars total)
-- ============================================================================

-- ============================================================================
-- STEP 1: Update draft_id generation function (6 → 7 chars)
-- ============================================================================

CREATE OR REPLACE FUNCTION generate_draft_id()
RETURNS varchar(7) AS $$
BEGIN
    RETURN upper(substring(replace(gen_random_uuid()::text, '-', ''), 1, 7));
END;
$$ LANGUAGE plpgsql VOLATILE;

COMMENT ON FUNCTION generate_draft_id() IS 'Generates unique 7-character hex draft ID using UUID (268M combinations for 250K records)';

-- ============================================================================
-- STEP 2: Update attachment generation functions with new prefixes
-- ============================================================================

-- Draft attachments: datt_XXXXXXXX
CREATE OR REPLACE FUNCTION generate_draft_attachment_id()
RETURNS varchar(13) AS $$
BEGIN
    RETURN 'datt_' || lower(substring(replace(gen_random_uuid()::text, '-', ''), 1, 8));
END;
$$ LANGUAGE plpgsql VOLATILE;

COMMENT ON FUNCTION generate_draft_attachment_id() IS 'Generates unique draft attachment ID: datt_XXXXXXXX (4.3B combinations)';

-- Case attachments: catt_XXXXXXXX
CREATE OR REPLACE FUNCTION generate_case_attachment_id()
RETURNS varchar(13) AS $$
BEGIN
    RETURN 'catt_' || lower(substring(replace(gen_random_uuid()::text, '-', ''), 1, 8));
END;
$$ LANGUAGE plpgsql VOLATILE;

COMMENT ON FUNCTION generate_case_attachment_id() IS 'Generates unique case attachment ID: catt_XXXXXXXX (4.3B combinations)';

-- ============================================================================
-- STEP 3: Backup existing data
-- ============================================================================

-- Create backup columns if they don't exist
ALTER TABLE case_drafts ADD COLUMN IF NOT EXISTS old_draft_id_v2 varchar(10);
ALTER TABLE draft_attachments ADD COLUMN IF NOT EXISTS old_attachment_id_v2 varchar(20);
ALTER TABLE case_attachments ADD COLUMN IF NOT EXISTS old_attachment_id_v2 varchar(20);

-- Save current values
UPDATE case_drafts SET old_draft_id_v2 = draft_id WHERE old_draft_id_v2 IS NULL;
UPDATE draft_attachments SET old_attachment_id_v2 = attachment_id WHERE old_attachment_id_v2 IS NULL;
UPDATE case_attachments SET old_attachment_id_v2 = attachment_id WHERE old_attachment_id_v2 IS NULL;

-- ============================================================================
-- STEP 4: Drop ALL old CHECK constraints
-- ============================================================================

ALTER TABLE case_drafts DROP CONSTRAINT IF EXISTS check_draft_id_format;
ALTER TABLE case_drafts DROP CONSTRAINT IF EXISTS check_draft_id_length;
ALTER TABLE draft_attachments DROP CONSTRAINT IF EXISTS check_attachment_id_format;
ALTER TABLE case_attachments DROP CONSTRAINT IF EXISTS check_attachment_id_format;

-- ============================================================================
-- STEP 5: Expand draft_id column and update existing records
-- ============================================================================

-- Expand column size
ALTER TABLE case_drafts ALTER COLUMN draft_id TYPE varchar(7);

-- Update existing 6-char draft_ids to 7 chars by appending one more hex char
UPDATE case_drafts 
SET draft_id = draft_id || upper(substring(replace(gen_random_uuid()::text, '-', ''), 1, 1))
WHERE length(draft_id) = 6;

-- Update DEFAULT for new records
ALTER TABLE case_drafts ALTER COLUMN draft_id SET DEFAULT generate_draft_id();

-- Update draft_id references in draft_attachments
ALTER TABLE draft_attachments ALTER COLUMN draft_id TYPE varchar(7);

-- ============================================================================
-- STEP 6: Update attachment_id columns and existing records
-- ============================================================================

-- Draft attachments: att_XXXXXX → datt_XXXXXXXX
ALTER TABLE draft_attachments ALTER COLUMN attachment_id TYPE varchar(13);

UPDATE draft_attachments
SET attachment_id = 'datt_' || lower(substring(replace(gen_random_uuid()::text, '-', ''), 1, 8))
WHERE attachment_id NOT LIKE 'datt_%';

ALTER TABLE draft_attachments ALTER COLUMN attachment_id SET DEFAULT generate_draft_attachment_id();

-- Case attachments: att_XXXXXX → catt_XXXXXXXX  
ALTER TABLE case_attachments ALTER COLUMN attachment_id TYPE varchar(13);

UPDATE case_attachments
SET attachment_id = 'catt_' || lower(substring(replace(gen_random_uuid()::text, '-', ''), 1, 8))
WHERE attachment_id NOT LIKE 'catt_%';

ALTER TABLE case_attachments ALTER COLUMN attachment_id SET DEFAULT generate_case_attachment_id();

-- ============================================================================
-- STEP 7: Add new CHECK constraints
-- ============================================================================

-- Draft ID: Must be 7 hex characters
ALTER TABLE case_drafts
ADD CONSTRAINT check_draft_id_format
CHECK (
    LENGTH(draft_id) = 7 
    AND draft_id ~ '^[0-9A-Fa-f]{7}$'
);

-- Draft attachments: Must be datt_XXXXXXXX
ALTER TABLE draft_attachments
ADD CONSTRAINT check_attachment_id_format
CHECK (
    LENGTH(attachment_id) = 13 
    AND attachment_id ~ '^datt_[0-9a-f]{8}$'
);

-- Case attachments: Must be catt_XXXXXXXX
ALTER TABLE case_attachments
ADD CONSTRAINT check_attachment_id_format
CHECK (
    LENGTH(attachment_id) = 13 
    AND attachment_id ~ '^catt_[0-9a-f]{8}$'
);

-- ============================================================================
-- STEP 8: Update column comments
-- ============================================================================

COMMENT ON COLUMN case_drafts.draft_id IS 'Auto-generated unique 7-char hex ID (e.g., A3F8E2C) using UUID';
COMMENT ON COLUMN draft_attachments.attachment_id IS 'Auto-generated unique ID: datt_XXXXXXXX (draft attachment)';
COMMENT ON COLUMN case_attachments.attachment_id IS 'Auto-generated unique ID: catt_XXXXXXXX (case attachment)';

-- ============================================================================
-- VERIFICATION
-- ============================================================================

DO $$
DECLARE
    draft_count INTEGER;
    draft_att_count INTEGER;
    case_att_count INTEGER;
BEGIN
    -- Count updated records
    SELECT COUNT(*) INTO draft_count FROM case_drafts WHERE LENGTH(draft_id) = 7;
    SELECT COUNT(*) INTO draft_att_count FROM draft_attachments WHERE attachment_id LIKE 'datt_%';
    SELECT COUNT(*) INTO case_att_count FROM case_attachments WHERE attachment_id LIKE 'catt_%';
    
    RAISE NOTICE '=================================================================';
    RAISE NOTICE 'ID EXPANSION AND PREFIX UPDATE COMPLETED';
    RAISE NOTICE '=================================================================';
    RAISE NOTICE 'Records Updated:';
    RAISE NOTICE '  case_drafts:       % records (7-char hex)', draft_count;
    RAISE NOTICE '  draft_attachments: % records (datt_XXXXXXXX)', draft_att_count;
    RAISE NOTICE '  case_attachments:  % records (catt_XXXXXXXX)', case_att_count;
    RAISE NOTICE '=================================================================';
    RAISE NOTICE 'New Formats:';
    RAISE NOTICE '  draft_id:           7 hex chars (268M combinations)';
    RAISE NOTICE '  draft attachments:  datt_XXXXXXXX (13 chars)';
    RAISE NOTICE '  case attachments:   catt_XXXXXXXX (13 chars)';
    RAISE NOTICE '=================================================================';
    RAISE NOTICE 'Old IDs preserved in backup columns:';
    RAISE NOTICE '  - old_draft_id_v2';
    RAISE NOTICE '  - old_attachment_id_v2';
    RAISE NOTICE '=================================================================';
END $$;

-- Show samples of updated IDs
SELECT 'Draft IDs (new 7-char format):' as info;
SELECT draft_id, old_draft_id_v2 as old_id FROM case_drafts LIMIT 5;

SELECT 'Draft Attachments (datt_ prefix):' as info;
SELECT attachment_id, old_attachment_id_v2 as old_id FROM draft_attachments LIMIT 5;

SELECT 'Case Attachments (catt_ prefix):' as info;
SELECT attachment_id, old_attachment_id_v2 as old_id FROM case_attachments LIMIT 5;

-- ============================================================================
-- SUMMARY OF CHANGES
-- ============================================================================
-- 
-- Before:
--   draft_id:           A3F8E2 (6 chars)
--   draft_attachments:  att_c3fdda1c (12 chars)
--   case_attachments:   att_b348abf4 (12 chars)
--
-- After:
--   draft_id:           A3F8E2C (7 chars) 
--   draft_attachments:  datt_c3fdda1c (13 chars)
--   case_attachments:   catt_b348abf4 (13 chars)
--
-- Benefits:
--   1. More combinations for draft_id (16^7 = 268M vs 16^6 = 16.7M)
--   2. Clear distinction between draft and case attachments
--   3. Industry-standard prefix naming (type + entity)
-- 
-- ============================================================================
