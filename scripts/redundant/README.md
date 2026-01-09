# Redundant Scripts

These scripts were used for one-time migrations and are kept for reference only.

## ⚠️ Do NOT Run These Scripts Again

All scripts in this folder have already been executed and their changes are permanent.

---

## Scripts

### `migrate_existing_ids_to_uuid_format.sql`
**Status:** ✅ Executed on Jan 9, 2026  
**Purpose:** One-time migration to convert all existing IDs from old format to UUID-based format  
**Records migrated:** 75,944 records  
- case_drafts: 9 records
- draft_attachments: 2 records
- case_attachments: 18,954 records
- case_comments: 56,979 records

### `cleanup_case_drafts_indexes.sql`
**Status:** ✅ Executed on Jan 8, 2026  
**Purpose:** Removed unnecessary indexes from case_drafts table  
**Action:** Kept only essential indexes for performance

### `final_index_cleanup.sql`
**Status:** ✅ Executed on Jan 8, 2026  
**Purpose:** Final cleanup of remaining unwanted indexes  
**Action:** Dropped created_at and salesforce_case_id indexes

### `cleanup_backup_columns.sql`
**Status:** ⏳ Optional - Not yet executed  
**Purpose:** Remove backup columns created during ID migration  
**Action:** Drops old_draft_id, old_attachment_id, old_comment_id columns  
**Note:** Run this only after verifying the migration was successful

---

## Current Active Scripts

Located in parent directory (`../`):
- `update_all_id_generation_functions.sql` - Reference for ID generation functions
- `add_id_format_constraints.sql` - Constraints for UUID-based ID formats

