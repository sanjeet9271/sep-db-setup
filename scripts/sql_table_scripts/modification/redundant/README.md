# Redundant Migration Scripts

This folder contains migration scripts that have already been executed successfully and are kept for historical reference only.

## ⚠️ Important Notice

**DO NOT RE-RUN** these scripts unless you are setting up a completely new database from scratch. These modifications have already been applied to the production/development database.

---

## Scripts in This Folder

### 1. `add_meta_column_to_draft_attachments.sql`
- **Date Executed**: January 13, 2026
- **Purpose**: Added `meta JSONB` column to `draft_attachments` table
- **Changes**:
  - Added `meta` column for storing frontend metadata (UI section, custom fields, etc.)
  - Created GIN index `idx_draft_attachments_meta` for efficient JSONB queries
- **Status**: ✅ Completed successfully

### 2. `convert_timestamps_to_utc.sql`
- **Date Executed**: January 2026
- **Purpose**: Standardized all timestamp columns to use UTC timezone explicitly
- **Changes**:
  - Updated `DEFAULT` values to use `TIMEZONE('UTC', NOW())`
  - Updated trigger functions to use UTC timestamps
  - Affected tables: `case_drafts`, `draft_attachments`, `case_attachments`, `case_comments`, `cases`, `employee`
- **Status**: ✅ Completed successfully

### 3. `expand_ids_and_update_prefixes.sql`
- **Date Executed**: January 2026
- **Purpose**: Expanded `draft_id` to 7 characters and updated attachment prefixes
- **Changes**:
  - Expanded `draft_id` from 6 to 7 characters
  - Updated attachment prefixes (intermediate version)
  - Handled constraints and existing data migration
- **Status**: ✅ Completed successfully (superseded by later migration)

### 4. `update_all_id_generation_functions.sql`
- **Date Executed**: January 2026
- **Purpose**: Migrated all ID generation functions to UUID-based approach
- **Changes**:
  - Updated `generate_draft_id()` to use `gen_random_uuid()`
  - Updated `generate_attachment_id()` functions
  - Updated `generate_comment_id()` function
  - Ensured collision-free ID generation with cryptographic randomness
  - Updated column types and DEFAULT values
- **Status**: ✅ Completed successfully

### 5. `update_attachment_prefixes_and_cleanup.sql`
- **Date Executed**: January 13, 2026
- **Purpose**: Final update to attachment prefixes and cleanup of backup columns
- **Changes**:
  - Changed attachment prefixes:
    - Draft attachments: `datt_` → `d_att_` (14 chars)
    - Case attachments: `catt_` → `c_att_` (14 chars)
  - Removed backup columns: `old_attachment_id`, `old_attachment_id_v2`
  - Updated 17 draft attachments and 18,954 case attachments
  - Re-added CHECK constraints with new patterns
- **Status**: ✅ Completed successfully

---

## Current ID Format Standards

After all migrations, the current ID formats are:

| Table | ID Column | Format | Example | Length |
|-------|-----------|--------|---------|--------|
| `case_drafts` | `draft_id` | 7 hex chars | `A3F8E2C` | 7 |
| `draft_attachments` | `attachment_id` | `d_att_` + 8 hex | `d_att_a3f8e2c9` | 14 |
| `case_attachments` | `attachment_id` | `c_att_` + 8 hex | `c_att_b348abf4` | 14 |
| `case_comments` | `comment_id` | `cmt_` + 8 hex | `cmt_7f3a2b1c` | 12 |

All IDs use `gen_random_uuid()` for collision-free generation.

---

## If You Need to Set Up a New Database

If you're setting up a completely new database from scratch:

1. **DO NOT** run these migration scripts
2. **INSTEAD**, use the creation scripts in `../creation/` which already include all these changes
3. The creation scripts are always up-to-date with the latest schema

---

## Documentation

For more details on ID formats and constraints, see:
- `../add_id_format_constraints.sql` - Current active constraints
- `../ID_FORMAT_CHANGES_SUMMARY.md` - Detailed change history

---

**Last Updated**: January 13, 2026
