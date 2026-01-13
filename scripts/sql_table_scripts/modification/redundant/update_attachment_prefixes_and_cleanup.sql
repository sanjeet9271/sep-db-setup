-- ============================================================================
-- UPDATE ATTACHMENT PREFIXES AND CLEANUP BACKUP COLUMNS
-- ============================================================================
-- Purpose: Change attachment prefixes:
--   - datt_ -> d_att_ (draft attachments)
--   - catt_ -> c_att_ (case attachments)
-- Also remove backup columns: old_attachment_id, old_attachment_id_v2
-- ============================================================================

BEGIN;

-- ============================================================================
-- STEP 1: DROP EXISTING CHECK CONSTRAINTS
-- ============================================================================
DO $$
BEGIN
    -- Drop draft_attachments constraint if exists
    IF EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'check_attachment_id_format'
        AND conrelid = 'draft_attachments'::regclass
    ) THEN
        ALTER TABLE draft_attachments DROP CONSTRAINT check_attachment_id_format;
        RAISE NOTICE '[1/8] Dropped draft_attachments check_attachment_id_format constraint';
    END IF;
    
    -- Drop case_attachments constraint if exists
    IF EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'check_attachment_id_format'
        AND conrelid = 'case_attachments'::regclass
    ) THEN
        ALTER TABLE case_attachments DROP CONSTRAINT check_attachment_id_format;
        RAISE NOTICE '[2/8] Dropped case_attachments check_attachment_id_format constraint';
    END IF;
END $$;

-- ============================================================================
-- STEP 2: UPDATE GENERATION FUNCTIONS
-- ============================================================================

-- Draft Attachments: d_att_XXXXXXXX (14 chars total)
CREATE OR REPLACE FUNCTION generate_draft_attachment_id()
RETURNS varchar(14) AS $$
BEGIN
    RETURN 'd_att_' || lower(substring(replace(gen_random_uuid()::text, '-', ''), 1, 8));
END;
$$ LANGUAGE plpgsql VOLATILE;

DO $$ BEGIN RAISE NOTICE '[3/8] Updated generate_draft_attachment_id() function (d_att_XXXXXXXX)'; END $$;

-- Case Attachments: c_att_XXXXXXXX (14 chars total)
CREATE OR REPLACE FUNCTION generate_case_attachment_id()
RETURNS varchar(14) AS $$
BEGIN
    RETURN 'c_att_' || lower(substring(replace(gen_random_uuid()::text, '-', ''), 1, 8));
END;
$$ LANGUAGE plpgsql VOLATILE;

DO $$ BEGIN RAISE NOTICE '[4/8] Updated generate_case_attachment_id() function (c_att_XXXXXXXX)'; END $$;

-- ============================================================================
-- STEP 3: ALTER COLUMN TYPES TO ACCOMMODATE NEW LENGTH
-- ============================================================================

-- Draft attachments: 13 -> 14 characters
ALTER TABLE draft_attachments 
ALTER COLUMN attachment_id TYPE VARCHAR(14);

DO $$ BEGIN RAISE NOTICE '[5/8] Updated draft_attachments.attachment_id column to VARCHAR(14)'; END $$;

-- Case attachments: 13 -> 14 characters
ALTER TABLE case_attachments 
ALTER COLUMN attachment_id TYPE VARCHAR(14);

DO $$ BEGIN RAISE NOTICE '[6/8] Updated case_attachments.attachment_id column to VARCHAR(14)'; END $$;

-- ============================================================================
-- STEP 4: UPDATE EXISTING IDs (PRESERVE ALL OTHER DATA)
-- ============================================================================

-- Update draft attachments: datt_ -> d_att_
UPDATE draft_attachments
SET attachment_id = REPLACE(attachment_id, 'datt_', 'd_att_')
WHERE attachment_id LIKE 'datt_%';

DO $$
DECLARE
    updated_count INTEGER;
BEGIN
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    RAISE NOTICE '[7/8] Updated % draft attachment IDs (datt_ -> d_att_)', updated_count;
END $$;

-- Update case attachments: catt_ -> c_att_
UPDATE case_attachments
SET attachment_id = REPLACE(attachment_id, 'catt_', 'c_att_')
WHERE attachment_id LIKE 'catt_%';

DO $$
DECLARE
    updated_count INTEGER;
BEGIN
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    RAISE NOTICE '[8/8] Updated % case attachment IDs (catt_ -> c_att_)', updated_count;
END $$;

-- ============================================================================
-- STEP 5: RE-ADD CHECK CONSTRAINTS WITH NEW PATTERNS
-- ============================================================================

-- Draft attachments: d_att_ + 8 hex chars (length = 14)
ALTER TABLE draft_attachments
ADD CONSTRAINT check_attachment_id_format 
CHECK (length(attachment_id) = 14 AND attachment_id ~ '^d_att_[0-9a-f]{8}$');

DO $$ BEGIN RAISE NOTICE '[9/11] Added draft_attachments check_attachment_id_format constraint (d_att_[0-9a-f]{8})'; END $$;

-- Case attachments: c_att_ + 8 hex chars (length = 14)
ALTER TABLE case_attachments
ADD CONSTRAINT check_attachment_id_format 
CHECK (length(attachment_id) = 14 AND attachment_id ~ '^c_att_[0-9a-f]{8}$');

DO $$ BEGIN RAISE NOTICE '[10/11] Added case_attachments check_attachment_id_format constraint (c_att_[0-9a-f]{8})'; END $$;

-- ============================================================================
-- STEP 6: DROP BACKUP COLUMNS
-- ============================================================================

-- Drop backup columns from draft_attachments
ALTER TABLE draft_attachments 
DROP COLUMN IF EXISTS old_attachment_id,
DROP COLUMN IF EXISTS old_attachment_id_v2;

DO $$ BEGIN RAISE NOTICE '[11/11] Dropped backup columns from draft_attachments'; END $$;

-- Drop backup columns from case_attachments
ALTER TABLE case_attachments 
DROP COLUMN IF EXISTS old_attachment_id,
DROP COLUMN IF EXISTS old_attachment_id_v2;

DO $$ BEGIN RAISE NOTICE '[12/12] Dropped backup columns from case_attachments'; END $$;

-- ============================================================================
-- STEP 7: UPDATE COLUMN DEFAULTS
-- ============================================================================

ALTER TABLE draft_attachments 
ALTER COLUMN attachment_id SET DEFAULT generate_draft_attachment_id();

ALTER TABLE case_attachments 
ALTER COLUMN attachment_id SET DEFAULT generate_case_attachment_id();

DO $$ BEGIN RAISE NOTICE '[13/13] Updated DEFAULT constraints for both tables'; END $$;

-- ============================================================================
-- VERIFICATION
-- ============================================================================

DO $$
DECLARE
    draft_att_count INTEGER;
    case_att_count INTEGER;
    draft_invalid INTEGER;
    case_invalid INTEGER;
BEGIN
    -- Count updated records
    SELECT COUNT(*) INTO draft_att_count 
    FROM draft_attachments 
    WHERE attachment_id LIKE 'd_att_%';
    
    SELECT COUNT(*) INTO case_att_count 
    FROM case_attachments 
    WHERE attachment_id LIKE 'c_att_%';
    
    -- Check for any invalid formats
    SELECT COUNT(*) INTO draft_invalid 
    FROM draft_attachments 
    WHERE attachment_id !~ '^d_att_[0-9a-f]{8}$';
    
    SELECT COUNT(*) INTO case_invalid 
    FROM case_attachments 
    WHERE attachment_id !~ '^c_att_[0-9a-f]{8}$';
    
    RAISE NOTICE '====================================================================';
    RAISE NOTICE 'MIGRATION VERIFICATION';
    RAISE NOTICE '====================================================================';
    RAISE NOTICE 'Draft Attachments:';
    RAISE NOTICE '  - Total with d_att_ prefix: %', draft_att_count;
    RAISE NOTICE '  - Invalid format: %', draft_invalid;
    RAISE NOTICE '';
    RAISE NOTICE 'Case Attachments:';
    RAISE NOTICE '  - Total with c_att_ prefix: %', case_att_count;
    RAISE NOTICE '  - Invalid format: %', case_invalid;
    RAISE NOTICE '====================================================================';
    
    IF draft_invalid > 0 OR case_invalid > 0 THEN
        RAISE EXCEPTION 'Migration failed: Found invalid ID formats!';
    END IF;
    
    RAISE NOTICE 'SUCCESS: All attachment IDs updated successfully!';
    RAISE NOTICE '====================================================================';
END $$;

-- Show sample records
SELECT 
    'draft_attachments' as table_name,
    attachment_id,
    draft_id,
    file_name
FROM draft_attachments
LIMIT 3;

SELECT 
    'case_attachments' as table_name,
    attachment_id,
    LEFT(case_id, 20) as case_id,
    file_name
FROM case_attachments
LIMIT 3;

COMMIT;

DO $$ BEGIN 
    RAISE NOTICE '';
    RAISE NOTICE 'Transaction committed successfully!';
    RAISE NOTICE 'Backup columns removed: old_attachment_id, old_attachment_id_v2';
END $$;
