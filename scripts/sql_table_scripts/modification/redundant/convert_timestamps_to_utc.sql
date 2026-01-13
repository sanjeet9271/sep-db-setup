-- ============================================================================
-- CONVERT ALL TIMESTAMP DEFAULTS TO EXPLICIT UTC
-- ============================================================================
-- Purpose: Update all timestamp column defaults to use TIMEZONE('UTC', NOW())
-- This ensures consistent UTC timestamps across all servers/timezones
-- ============================================================================

-- ============================================================================
-- 1. Update case_drafts table
-- ============================================================================

ALTER TABLE case_drafts 
    ALTER COLUMN created_at SET DEFAULT TIMEZONE('UTC', NOW());

ALTER TABLE case_drafts 
    ALTER COLUMN updated_at SET DEFAULT TIMEZONE('UTC', NOW());

-- Update trigger function
CREATE OR REPLACE FUNCTION update_case_drafts_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = TIMEZONE('UTC', NOW());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 2. Update draft_attachments table
-- ============================================================================

ALTER TABLE draft_attachments 
    ALTER COLUMN created_at SET DEFAULT TIMEZONE('UTC', NOW());

-- ============================================================================
-- 3. Update case_attachments table
-- ============================================================================

ALTER TABLE case_attachments 
    ALTER COLUMN created_at SET DEFAULT TIMEZONE('UTC', NOW());

-- ============================================================================
-- 4. Update cases table
-- ============================================================================

ALTER TABLE cases 
    ALTER COLUMN synced_at SET DEFAULT TIMEZONE('UTC', NOW());

-- ============================================================================
-- 5. Update case_comments table
-- ============================================================================

ALTER TABLE case_comments 
    ALTER COLUMN created_at SET DEFAULT TIMEZONE('UTC', NOW());

-- Update trigger function if exists
CREATE OR REPLACE FUNCTION update_case_comments_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = TIMEZONE('UTC', NOW());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 6. Update employee table
-- ============================================================================

ALTER TABLE employee 
    ALTER COLUMN created_at SET DEFAULT TIMEZONE('UTC', NOW());

-- ============================================================================
-- VERIFICATION
-- ============================================================================

DO $$
DECLARE
    utc_count INTEGER;
    total_count INTEGER;
BEGIN
    -- Count columns using UTC
    SELECT COUNT(*) INTO utc_count
    FROM information_schema.columns
    WHERE table_schema = 'public'
        AND data_type LIKE '%timestamp%'
        AND column_default LIKE '%timezone%UTC%';
    
    -- Count all timestamp columns with defaults
    SELECT COUNT(*) INTO total_count
    FROM information_schema.columns
    WHERE table_schema = 'public'
        AND data_type LIKE '%timestamp%'
        AND column_default IS NOT NULL;
    
    RAISE NOTICE '=================================================================';
    RAISE NOTICE 'UTC TIMESTAMP CONVERSION COMPLETED';
    RAISE NOTICE '=================================================================';
    RAISE NOTICE 'Timestamp columns with UTC: % out of %', utc_count, total_count;
    RAISE NOTICE '=================================================================';
    
    IF utc_count = total_count THEN
        RAISE NOTICE 'SUCCESS: All timestamp columns now use UTC!';
    ELSE
        RAISE WARNING 'WARNING: % columns still not using UTC', (total_count - utc_count);
    END IF;
    
    RAISE NOTICE '=================================================================';
END $$;

-- List all timestamp columns and their defaults
SELECT 
    table_name,
    column_name,
    column_default,
    CASE 
        WHEN column_default LIKE '%timezone%UTC%' THEN '[UTC]'
        ELSE '[!!!]'
    END as status
FROM information_schema.columns
WHERE table_schema = 'public'
    AND data_type LIKE '%timestamp%'
    AND column_default IS NOT NULL
ORDER BY table_name, column_name;

-- ============================================================================
-- IMPORTANT NOTES
-- ============================================================================
-- 
-- 1. This ONLY affects NEW records - existing records are unchanged
-- 2. TIMESTAMPTZ stores values in UTC internally regardless of input
-- 3. This ensures the DEFAULT expression explicitly uses UTC
-- 4. Prevents timezone-related bugs when servers have different TZ settings
-- 
-- ============================================================================

