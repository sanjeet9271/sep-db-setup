-- ============================================================================
-- ADD META COLUMN TO draft_attachments TABLE
-- ============================================================================
-- Purpose: Add JSONB meta column for frontend metadata storage
-- Column: meta (JSONB) - Stores UI section, custom fields, etc.
-- ============================================================================

-- Add meta column
ALTER TABLE draft_attachments 
ADD COLUMN IF NOT EXISTS meta JSONB;

-- Add comment
COMMENT ON COLUMN draft_attachments.meta IS 'Frontend metadata (UI section, custom fields, etc.) stored as JSON';

-- Create GIN index for efficient JSONB queries (optional but recommended)
CREATE INDEX IF NOT EXISTS idx_draft_attachments_meta 
ON draft_attachments USING GIN(meta);

-- Verification
DO $$
DECLARE
    column_exists BOOLEAN;
BEGIN
    -- Check if column exists
    SELECT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'draft_attachments' 
        AND column_name = 'meta'
    ) INTO column_exists;
    
    RAISE NOTICE '=================================================================';
    RAISE NOTICE 'META COLUMN ADDITION';
    RAISE NOTICE '=================================================================';
    
    IF column_exists THEN
        RAISE NOTICE 'Column added successfully: draft_attachments.meta (JSONB)';
        RAISE NOTICE 'Index created: idx_draft_attachments_meta (GIN)';
        RAISE NOTICE 'Purpose: Store frontend metadata (UI section, custom fields, etc.)';
    ELSE
        RAISE WARNING 'Column addition failed!';
    END IF;
    
    RAISE NOTICE '=================================================================';
END $$;

-- Show updated table structure
SELECT 
    column_name,
    data_type,
    character_maximum_length,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'draft_attachments'
ORDER BY ordinal_position;

-- ============================================================================
-- USAGE EXAMPLES
-- ============================================================================
/*
-- Insert with meta data:
INSERT INTO draft_attachments (draft_id, file_name, s3_key, meta)
VALUES (
    'A3F8E2C', 
    'photo.jpg', 
    's3://bucket/path/photo.jpg',
    '{"ui_section": "product_photos", "uploaded_by": "mobile_app", "version": 1}'::jsonb
);

-- Query by meta field:
SELECT * FROM draft_attachments 
WHERE meta->>'ui_section' = 'product_photos';

-- Update meta field:
UPDATE draft_attachments 
SET meta = jsonb_set(meta, '{version}', '2')
WHERE attachment_id = 'datt_abc123';

-- Add field to existing meta:
UPDATE draft_attachments
SET meta = COALESCE(meta, '{}'::jsonb) || '{"new_field": "value"}'::jsonb
WHERE attachment_id = 'datt_abc123';
*/
