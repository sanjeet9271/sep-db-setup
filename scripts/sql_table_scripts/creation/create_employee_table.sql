-- ============================================================================
-- EMPLOYEE TABLE CREATION SCRIPT
-- ============================================================================
-- Purpose: Employee information
-- Dependencies: None (base table)
-- ============================================================================

-- Drop table if exists (use with caution in production)
-- DROP TABLE IF EXISTS employee CASCADE;

-- Create employee table
CREATE TABLE employee (
    id UUID PRIMARY KEY NOT NULL,
    employee_code VARCHAR(50) NOT NULL,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL,
    department VARCHAR(100) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================================
-- INDEXES FOR PERFORMANCE
-- ============================================================================

-- Index for employee code lookups
CREATE INDEX idx_employee_code ON employee(employee_code);

-- Index for email lookups
CREATE INDEX idx_employee_email ON employee(email);

-- Index for department filtering
CREATE INDEX idx_employee_department ON employee(department);

-- Index for active status filtering
CREATE INDEX idx_employee_is_active ON employee(is_active);

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON TABLE employee IS 'Employee information';
COMMENT ON COLUMN employee.id IS 'Primary Key - UUID identifier';
COMMENT ON COLUMN employee.employee_code IS 'Employee code (unique identifier)';
COMMENT ON COLUMN employee.name IS 'Employee full name';
COMMENT ON COLUMN employee.email IS 'Employee email address';
COMMENT ON COLUMN employee.department IS 'Department name';
COMMENT ON COLUMN employee.is_active IS 'Active status flag';
COMMENT ON COLUMN employee.created_at IS 'Timestamp when record was created';

-- ============================================================================
-- VERIFICATION
-- ============================================================================

-- Verify table creation
SELECT 
    'employee' as table_name,
    COUNT(*) as row_count,
    pg_size_pretty(pg_total_relation_size('employee')) as total_size
FROM employee;

