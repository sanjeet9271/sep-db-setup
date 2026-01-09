-- ============================================================
-- Create case_reference_numbers Table
-- ============================================================
-- Links MTP reference numbers to Salesforce case IDs

-- DROP TABLE IF EXISTS case_reference_numbers CASCADE;

CREATE TABLE case_reference_numbers (
    mtp_reference_number VARCHAR(50) PRIMARY KEY,
    case_id VARCHAR(18) NOT NULL
);

-- Create index on case_id for fast lookups
CREATE INDEX idx_case_reference_numbers_case_id ON case_reference_numbers(case_id);

-- Add comments for documentation
COMMENT ON TABLE case_reference_numbers IS 'Links MTP case reference numbers to Salesforce case IDs';
COMMENT ON COLUMN case_reference_numbers.mtp_reference_number IS 'MTP Case reference number (Primary Key)';
COMMENT ON COLUMN case_reference_numbers.case_id IS 'References Salesforce Case ID';

-- Display success message
DO $$
BEGIN
    RAISE NOTICE '✓ case_reference_numbers table created';
END $$;




