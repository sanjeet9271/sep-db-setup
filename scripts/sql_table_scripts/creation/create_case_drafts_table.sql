-- ============================================================================
-- CASE_DRAFTS TABLE CREATION SCRIPT
-- ============================================================================
-- Purpose: Store draft cases before submission to Salesforce
-- Dependencies: None (independent table)
-- ============================================================================

-- Drop table if exists (use with caution in production)
-- DROP TABLE IF EXISTS case_drafts CASCADE;

-- Create case_drafts table
CREATE TABLE case_drafts (
    draft_id VARCHAR(6) PRIMARY KEY,              -- Auto-generated (e.g., D3F8K2)
    user_id VARCHAR(100) NOT NULL,                -- Creator from TID token
    account_id VARCHAR(50) NOT NULL,              -- Account from TID token
    case_type VARCHAR(50),                        -- WarrantyClaim, RMARepair, etc.
    serial_number VARCHAR(100),                   -- Serial # for display + filtering
    product_description VARCHAR(255),             -- Product description for display
    subject VARCHAR(255),                         -- Subject/title for display
    case_data JSONB NOT NULL,                     -- Full case payload
    submission_status VARCHAR(20) NOT NULL DEFAULT 'draft',  -- draft|submitting|submitted|submission_failed
    salesforce_case_id VARCHAR(18),               -- Populated on success
    submission_error TEXT,                        -- Error message on failure
    submitted_at TIMESTAMPTZ,                     -- Submission timestamp
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), -- Creation timestamp
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()  -- Last update timestamp
);

-- ============================================================================
-- INDEXES FOR PERFORMANCE
-- ============================================================================

-- Index for filtering by user
CREATE INDEX idx_case_drafts_user_id ON case_drafts(user_id);

-- Index for filtering by account
CREATE INDEX idx_case_drafts_account_id ON case_drafts(account_id);

-- Index for filtering by submission status
CREATE INDEX idx_case_drafts_submission_status ON case_drafts(submission_status);

-- Index for filtering by case type
CREATE INDEX idx_case_drafts_case_type ON case_drafts(case_type);

-- Index for sorting by creation date
CREATE INDEX idx_case_drafts_created_at ON case_drafts(created_at DESC);

-- Index for sorting by update date
CREATE INDEX idx_case_drafts_updated_at ON case_drafts(updated_at DESC);

-- Index for Salesforce case ID lookups
CREATE INDEX idx_case_drafts_sf_case_id ON case_drafts(salesforce_case_id)
    WHERE salesforce_case_id IS NOT NULL;

-- Composite index for user + status (common query pattern)
CREATE INDEX idx_case_drafts_user_status ON case_drafts(user_id, submission_status);

-- Composite index for account + status
CREATE INDEX idx_case_drafts_account_status ON case_drafts(account_id, submission_status);

-- GIN index for JSONB queries on case_data
CREATE INDEX idx_case_drafts_case_data ON case_drafts USING GIN(case_data);

-- ============================================================================
-- TRIGGER FOR AUTOMATIC updated_at TIMESTAMP
-- ============================================================================

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_case_drafts_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
CREATE TRIGGER trigger_update_case_drafts_updated_at
    BEFORE UPDATE ON case_drafts
    FOR EACH ROW
    EXECUTE FUNCTION update_case_drafts_updated_at();

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON TABLE case_drafts IS 'Draft cases stored before submission to Salesforce';
COMMENT ON COLUMN case_drafts.draft_id IS 'Auto-generated draft ID (e.g., D3F8K2)';
COMMENT ON COLUMN case_drafts.user_id IS 'User ID from TID token who created the draft';
COMMENT ON COLUMN case_drafts.account_id IS 'Account ID from TID token for filtering';
COMMENT ON COLUMN case_drafts.case_type IS 'Type of case: WarrantyClaim, RMARepair, etc.';
COMMENT ON COLUMN case_drafts.serial_number IS 'Serial number for display and filtering';
COMMENT ON COLUMN case_drafts.product_description IS 'Product description for display';
COMMENT ON COLUMN case_drafts.subject IS 'Case subject/title for display';
COMMENT ON COLUMN case_drafts.case_data IS 'Full case payload as JSONB';
COMMENT ON COLUMN case_drafts.submission_status IS 'Status: draft, submitting, submitted, or submission_failed';
COMMENT ON COLUMN case_drafts.salesforce_case_id IS 'Salesforce Case ID populated on successful submission';
COMMENT ON COLUMN case_drafts.submission_error IS 'Error message if submission failed';
COMMENT ON COLUMN case_drafts.submitted_at IS 'Timestamp when draft was submitted';
COMMENT ON COLUMN case_drafts.created_at IS 'Timestamp when draft was created';
COMMENT ON COLUMN case_drafts.updated_at IS 'Timestamp when draft was last updated (auto-updated)';






