-- ============================================================
-- Create case_drafts Table with Auto-Generated draft_id
-- ============================================================
-- This script creates the case_drafts table for storing draft cases
-- with an auto-generated 6-character alphanumeric draft_id (e.g., D3F8K2)

-- Drop table if exists (use with caution)
-- DROP TABLE IF EXISTS case_drafts CASCADE;

-- Function to generate unique random 7-character hex ID using UUID
CREATE OR REPLACE FUNCTION generate_draft_id()
RETURNS varchar(7) AS $$
BEGIN
    RETURN upper(substring(replace(gen_random_uuid()::text, '-', ''), 1, 7));
END;
$$ LANGUAGE plpgsql VOLATILE;

-- Create the case_drafts table
CREATE TABLE case_drafts (
    draft_id VARCHAR(6) PRIMARY KEY DEFAULT generate_draft_id(),
    user_id VARCHAR(100) NOT NULL,
    case_type VARCHAR(50),
    serial_number VARCHAR(100),
    part_number VARCHAR(100),
    product_description VARCHAR(255),
    subject VARCHAR(255),
    case_data JSONB,
    submission_status VARCHAR(20) DEFAULT 'draft',
    salesforce_case_id VARCHAR(18),
    submission_error TEXT,
    submitted_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('UTC', NOW()),
    updated_at TIMESTAMPTZ DEFAULT TIMEZONE('UTC', NOW())
);

-- Create indexes for better query performance
CREATE INDEX idx_case_drafts_user_id ON case_drafts(user_id);
CREATE INDEX idx_case_drafts_case_type ON case_drafts(case_type);
CREATE INDEX idx_case_drafts_serial_number ON case_drafts(serial_number);
CREATE INDEX idx_case_drafts_part_number ON case_drafts(part_number);
CREATE INDEX idx_case_drafts_submission_status ON case_drafts(submission_status);

-- Composite index for user + status (common query pattern)
CREATE INDEX idx_case_drafts_user_status ON case_drafts(user_id, submission_status);

-- Create trigger to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_case_drafts_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = TIMEZONE('UTC', NOW());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_case_drafts_updated_at
BEFORE UPDATE ON case_drafts
FOR EACH ROW
EXECUTE FUNCTION update_case_drafts_updated_at();

-- Add constraint to ensure valid submission_status values
ALTER TABLE case_drafts
ADD CONSTRAINT check_submission_status
CHECK (submission_status IN ('draft', 'submitting', 'submitted', 'submission_failed'));

-- Add constraint to ensure draft_id is exactly 6 characters and not empty
ALTER TABLE case_drafts
ADD CONSTRAINT check_draft_id_length
CHECK (LENGTH(draft_id) = 6 AND draft_id != '');

-- Comment on table and columns for documentation
COMMENT ON TABLE case_drafts IS 'Stores draft case submissions with auto-generated 6-character draft IDs';
COMMENT ON COLUMN case_drafts.draft_id IS 'Auto-generated unique 7-character hex ID (e.g., A3F8E2C)';
COMMENT ON COLUMN case_drafts.user_id IS 'Creator from TID token';
COMMENT ON COLUMN case_drafts.case_type IS 'Type of case: WarrantyClaim, RMARepair, etc.';
COMMENT ON COLUMN case_drafts.serial_number IS 'Serial number for display and filtering';
COMMENT ON COLUMN case_drafts.part_number IS 'Part number for display and filtering';
COMMENT ON COLUMN case_drafts.product_description IS 'Product description for display';
COMMENT ON COLUMN case_drafts.subject IS 'Subject/title for display';
COMMENT ON COLUMN case_drafts.case_data IS 'Full case payload in JSON format';
COMMENT ON COLUMN case_drafts.submission_status IS 'Status: draft|submitting|submitted|submission_failed';
COMMENT ON COLUMN case_drafts.salesforce_case_id IS 'Populated on successful submission to Salesforce';
COMMENT ON COLUMN case_drafts.submission_error IS 'Error message on submission failure';
COMMENT ON COLUMN case_drafts.submitted_at IS 'Timestamp when case was submitted';
COMMENT ON COLUMN case_drafts.created_at IS 'Timestamp when draft was created';
COMMENT ON COLUMN case_drafts.updated_at IS 'Timestamp when draft was last updated';

-- Display success message
DO $$
BEGIN
    RAISE NOTICE 'case_drafts table created successfully with unique draft_id generation!';
END $$;
