# Case Management Tables
## Complete Schema Documentation

**Date:** December 29, 2025  
**Database:** PostgreSQL (Aurora)  
**Environment:** AWS RDS

---

## 📋 Table of Contents

1. [cases](#1-cases) - Salesforce cases (synced from SF)
2. [case_drafts](#2-case_drafts) - Draft case submissions
3. [draft_attachments](#3-draft_attachments) - Attachments for draft cases
4. [case_comments](#4-case_comments) - Comments for Salesforce sync
5. [case_attachments](#5-case_attachments) - Attachments for Salesforce sync
6. [case_reference_numbers](#6-case_reference_numbers) - MTP reference mapping
7. [Summary](#summary)

---

## 1. cases

**Purpose:** Store Salesforce cases synced from Salesforce (read-only mirror)

### Schema

| Column | Type | Constraints | Description |
|:-------|:-----|:------------|:------------|
| **case_id** | `VARCHAR(18)` | PK | Salesforce Case ID (18 characters) |
| case_number | `VARCHAR(20)` | NOT NULL | Salesforce Case Number (e.g., `06214749`) |
| case_type | `VARCHAR(50)` | | Case type from Salesforce |
| account_id | `VARCHAR(50)` | | Salesforce Account ID |
| status | `VARCHAR(50)` | | Case status (New, Closed, etc.) |
| progress | `INTEGER` | | Case progress indicator |
| serial_number | `VARCHAR(100)` | | Device serial number |
| part_number | `VARCHAR(100)` | | Part number for display + filtering |
| product_description | `VARCHAR(255)` | | Product description |
| subject | `VARCHAR(255)` | | Case subject/title |
| submitted_at | `TIMESTAMPTZ` | | When case was submitted in Salesforce |
| case_data | `JSONB` | NOT NULL | Full case data from Salesforce (case, laborCharges, otherCharges, serviceParts) |
| synced_at | `TIMESTAMPTZ` | NOT NULL | When record was last synced from Salesforce |

### Sample Records

```json
Record 1:
{
  "case_id": "500WR00000hHS98YAG",
  "case_number": "06214749",
  "case_type": null,
  "account_id": null,
  "status": "New",
  "progress": null,
  "serial_number": null,
  "product_description": null,
  "subject": "Forestry : Advice Attached # INV250497 - $ 4,334.90",
  "submitted_at": "2025-08-07 21:15:48+00:00",
  "case_data": {
    "case": {
      "Id": "500WR00000hHS98YAG",
      "CaseNumber": "06214749",
      "Subject": "Forestry : Advice Attached # INV250497 - $ 4,334.90",
      "Origin": "TNL E-Mail inbox",
      "Status": "Closed",
      "Priority": "Medium",
      "Description": "Attn: Advice attached If you have any questions...",
      "ExternalCaseStatus": "New",
      "CurrencyIsoCode": "USD"
    },
    "laborCharges": [],
    "otherCharges": [],
    "serviceParts": []
  },
  "synced_at": "2025-12-25 18:32:36.968678+00:00"
}

Record 2:
{
  "case_id": "500WR00000hHRw1YAG",
  "case_number": "06214748",
  "case_type": null,
  "account_id": "300000015095361",
  "status": "New",
  "progress": null,
  "serial_number": null,
  "product_description": null,
  "subject": "po P005160//SO##1681502.",
  "submitted_at": "2025-08-07 21:14:43+00:00",
  "case_data": {
    "case": {
      "Id": "500WR00000hHRw1YAG",
      "CaseNumber": "06214748",
      "Subject": "po P005160//SO##1681502.",
      "Origin": "Trimble Orders E-mail",
      "Status": "Closed",
      "Priority": "Medium",
      "Account": {
        "ExternalID": "300000015095361"
      },
      "Description": "Hello Nick, Please approve so that orders...",
      "ExternalCaseStatus": "New",
      "CurrencyIsoCode": "USD"
    },
    "laborCharges": [],
    "otherCharges": [],
    "serviceParts": []
  },
  "synced_at": "2025-12-25 18:32:36.968783+00:00"
}
```

**Total Records:** 300,182

---

## 2. case_drafts

**Purpose:** Store draft case submissions with auto-generated 6-character draft IDs

### Schema

| Column | Type | Constraints | Description |
|:-------|:-----|:------------|:------------|
| **draft_id** | `VARCHAR(6)` | PK, AUTO | Auto-generated 6-char ID (e.g., `R7VS3B`, `BFGR75`) |
| user_id | `VARCHAR(100)` | NOT NULL | Creator user ID from TID token |
| case_type | `VARCHAR(50)` | | Case type: `WarrantyClaim`, `RMARepair`, etc. |
| serial_number | `VARCHAR(100)` | | Device serial number for display and filtering |
| part_number | `VARCHAR(100)` | | Part number for display + filtering |
| product_description | `VARCHAR(255)` | | Product description text |
| subject | `VARCHAR(255)` | | Case subject/title |
| case_data | `JSONB` | | Full case payload (Case, Labor, ServiceParts, OtherCosts) |
| submission_status | `VARCHAR(20)` | DEFAULT `'draft'` | `draft` \| `submitting` \| `submitted` \| `submission_failed` |
| salesforce_case_id | `VARCHAR(18)` | | Salesforce Case ID (18 chars) - populated on successful submission |
| submission_error | `TEXT` | | Error message if submission fails |
| submitted_at | `TIMESTAMPTZ` | | Timestamp when successfully submitted to Salesforce |
| created_at | `TIMESTAMPTZ` | DEFAULT `NOW()` | Record creation timestamp |
| updated_at | `TIMESTAMPTZ` | DEFAULT `NOW()` | Auto-updates on any modification |

### Constraints
- `draft_id`: Exactly 6 characters, NOT NULL, NOT EMPTY, UNIQUE
- `submission_status`: Must be one of: `draft`, `submitting`, `submitted`, `submission_failed`

### Sample Records

```json
Record 1:
{
  "draft_id": "6PM4EK",
  "user_id": "sanjeet_kumar@trimble.com",
  "case_type": "WarrantyClaim",
  "serial_number": "SN987654321",
  "product_description": "GPS Module - Example Product",
  "subject": "Defective GPS Module - Loss of Signal",
  "case_data": {
    "Case": {
      "Origin": "Web",
      "Status": "New",
      "Subject": "Defective GPS Module - Loss of Signal",
      "Priority": "Medium",
      "PartNumber": "GPS-MOD-2000",
      "Description": "Customer reported intermittent GPS signal loss.",
      "ContactEmail": "customer@example.com",
      "PolicyNumber": "WP-2024-999999",
      "SerialNumber": "SN987654321"
    },
    "Labor": {
      "Rate": 125.0,
      "Hours": 2.5,
      "IsWarrantable": true,
      "CurrencyIsoCode": "USD"
    },
    "ServiceParts": [
      {
        "Price": 450.0,
        "Quantity": 1,
        "PartNumber": "GPS-MOD-2000",
        "IsWarrantable": true,
        "CurrencyIsoCode": "USD"
      }
    ]
  },
  "submission_status": "draft",
  "salesforce_case_id": null,
  "submission_error": null,
  "submitted_at": null,
  "created_at": "2025-12-29 09:53:22.985404+00:00",
  "updated_at": "2025-12-29 09:53:22.985404+00:00"
}

Record 2:
{
  "draft_id": "BFGR75",
  "user_id": "sanjeet_kumar@trimble.com",
  "case_type": "WarrantyClaim",
  "serial_number": "SN123456789",
  "product_description": "Customer reported intermittent GPS signal loss. Device fails to acquire satellite lock after 5 minutes. Issue persists across multiple power cycles.",
  "subject": "Defective GPS Module - Loss of Signal",
  "case_data": {
    "Case": {
      "Origin": "Web",
      "Status": "New",
      "Failure": "GPS receiver chip malfunction",
      "Subject": "Defective GPS Module - Loss of Signal",
      "Symptom": "No satellite lock",
      "PlanType": "Extended Warranty",
      "Priority": "Medium",
      "PartNumber": "GPS-MOD-2000",
      "PolicyType": "Standard Warranty",
      "Description": "Customer reported intermittent GPS signal loss. Device fails to acquire satellite lock after 5 minutes. Issue persists across multiple power cycles.",
      "ContactEmail": "customer.support@example.com",
      "DateReceived": "2024-01-15",
      "DateRepaired": "2024-01-16",
      "PolicyNumber": "WP-2024-001234",
      "SerialNumber": "SN123456789",
      "PartAssistance": "Requested expedited shipping for replacement module",
      "PartnerCRMCase": "CRM-2024-789",
      "TypeOfContract": "Parts and Labor",
      "AtlasCaseNumber": "ATL-2024-00123",
      "CurrencyIsoCode": "USD",
      "FailureCategory": "GPS_MODULE_FAILURE",
      "FailureVerified": true,
      "TechnicianEmail": "john.technician@example.com",
      "SalesOrderNumber": "SO-2024-5678",
      "RepairDescription": "Replaced main GPS module (P/N GPS-MOD-2000). Tested signal acquisition - successful lock within 30 seconds. Verified accuracy within 3 meters.",
      "TechnicalAnalysis": "GPS receiver IC showed signs of moisture damage. Likely due to improper sealing during manufacturing.",
      "WarrantyException": "",
      "DatePreviousRepair": "",
      "ExternalCaseStatus": "Open",
      "PreviousAtlasNumber": "",
      "ReturnToLocationText": "Return to: Trimble Service Center, 123 Main St, Denver CO 80202",
      "OtherServiceBulletins": "SB-2023-045, SB-2023-078",
      "RepairedProductPartNumber": "GPS-MOD-2000",
      "ServiceBulletinExternalId": "SB-2024-001",
      "StepsTakenToVerifyFailure": "1. Tested GPS signal acquisition in open area. 2. Verified antenna connection. 3. Performed firmware update. 4. Tested with external antenna. Issue persists.",
      "ApplicableFailureCategories": "GPS_MODULE_FAILURE, HARDWARE_DEFECT"
    },
    "Labor": {
      "Rate": 125.0,
      "Hours": 2.5,
      "IsWarrantable": true,
      "RequestedHours": 3.0,
      "CurrencyIsoCode": "USD"
    },
    "OtherCosts": [
      {
        "UnitUsage": 1,
        "AmountPerUnit": 35.0,
        "IsWarrantable": true,
        "CurrencyIsoCode": "USD",
        "CostCategoryType": "Shipping"
      },
      {
        "UnitUsage": 1,
        "AmountPerUnit": 15.0,
        "IsWarrantable": false,
        "CurrencyIsoCode": "USD",
        "CostCategoryType": "Handling Fee"
      }
    ],
    "ServiceParts": [
      {
        "Price": 450.0,
        "APIPrice": 450.0,
        "Quantity": 1,
        "APIMessage": "Price retrieved successfully",
        "ExternalId": "EXT-GPS-001",
        "PartNumber": "GPS-MOD-2000",
        "ReturnPart": true,
        "MissingPrice": false,
        "IsWarrantable": true,
        "CurrencyIsoCode": "USD",
        "IsPartPickedFromBOM": true,
        "AdditionalReimbursement": "Expedited Shipping",
        "IsPartRecentlyPurchased": false,
        "AdditionalReimbursementAmount": 25.0
      },
      {
        "Price": 75.5,
        "APIPrice": 75.5,
        "Quantity": 1,
        "APIMessage": "Price retrieved successfully",
        "ExternalId": "EXT-ANT-002",
        "PartNumber": "ANT-GPS-100",
        "ReturnPart": false,
        "MissingPrice": false,
        "IsWarrantable": true,
        "CurrencyIsoCode": "USD",
        "IsPartPickedFromBOM": true,
        "AdditionalReimbursement": "",
        "IsPartRecentlyPurchased": true,
        "AdditionalReimbursementAmount": 0
      }
    ]
  },
  "submission_status": "draft",
  "salesforce_case_id": null,
  "submission_error": null,
  "submitted_at": null,
  "created_at": "2025-12-29 10:02:16.133192+00:00",
  "updated_at": "2025-12-29 10:02:16.133192+00:00"
}
```

**Total Records:** 2

---

## 3. draft_attachments

**Purpose:** Store file attachments associated with draft cases (before submission)

### Schema

| Column | Type | Constraints | Description |
|:-------|:-----|:------------|:------------|
| **attachment_id** | `VARCHAR(10)` | PK | Attachment identifier (manual or auto-generated) |
| draft_id | `VARCHAR(6)` | NOT NULL, FK | References `case_drafts.draft_id` |
| file_name | `VARCHAR(255)` | NOT NULL | Original filename |
| content_type | `VARCHAR(100)` | | MIME type (e.g., image/png, application/pdf) |
| s3_key | `VARCHAR(500)` | NOT NULL | Full S3 path where file is stored |
| sync_status | `VARCHAR(20)` | DEFAULT `'uploaded'` | File upload/sync status |
| sync_error | `TEXT` | | Error message if upload fails |
| created_at | `TIMESTAMPTZ` | DEFAULT `NOW()` | File upload timestamp |

### Constraints
- `attachment_id`: PRIMARY KEY
- `draft_id`: FOREIGN KEY → `case_drafts.draft_id`
- Files are stored in S3 before case submission

### Sample Records

```
No records currently exist in this table.
This table is ready to store attachments associated with draft cases.
```

**Total Records:** 0

---

## 4. case_comments

**Purpose:** Store comments to be synced to Salesforce cases

### Schema

| Column | Type | Constraints | Description |
|:-------|:-----|:------------|:------------|
| **comment_id** | `VARCHAR(10)` | PK, AUTO | Auto-generated: `cmt_` + 4 chars (e.g., `cmt_x7k2`) |
| case_id | `VARCHAR(18)` | NOT NULL, FK | Salesforce Case ID (18 characters) |
| body | `TEXT` | NOT NULL | Comment text content (max 5000 characters) |
| created_by | `VARCHAR(100)` | NOT NULL | User ID who created the comment |
| sync_status | `VARCHAR(20)` | DEFAULT `'pending'` | `pending` \| `syncing` \| `synced` \| `sync_failed` |
| sf_comment_id | `VARCHAR(18)` | | Salesforce CaseComment ID after successful sync |
| sync_error | `TEXT` | | Error message if sync fails |
| created_at | `TIMESTAMPTZ` | DEFAULT `NOW()` | Comment creation timestamp |

### Constraints
- `comment_id`: Format = `cmt_xxxx` (exactly 8 characters total)
- `body`: Maximum 5000 characters
- `sync_status`: Must be one of: `pending`, `syncing`, `synced`, `sync_failed`

### Sample Records

```json
Record 1:
{
  "comment_id": "cmt_gjbp",
  "case_id": "5001234567890ABCDE",
  "body": "Escalating to engineering team for further investigation",
  "created_by": "user_2@trimble.com",
  "sync_status": "pending",
  "sf_comment_id": null,
  "sync_error": null,
  "created_at": "2025-12-29 17:29:55.930439+00:00"
}

Record 2:
{
  "comment_id": "cmt_t7aq",
  "case_id": "5001234567890ABCDE",
  "body": "Replacement part has been shipped - tracking #1Z999AA10123456784",
  "created_by": "user_3@trimble.com",
  "sync_status": "pending",
  "sf_comment_id": null,
  "sync_error": null,
  "created_at": "2025-12-29 17:29:55.930439+00:00"
}
```

**Total Records:** 56,979

---

## 5. case_attachments

**Purpose:** Store file attachments to be synced to Salesforce cases

### Schema

| Column | Type | Constraints | Description |
|:-------|:-----|:------------|:------------|
| **attachment_id** | `VARCHAR(10)` | PK, AUTO | Auto-generated: `att_` + 4 chars (e.g., `att_c8m4`) |
| case_id | `VARCHAR(18)` | NOT NULL, FK | Salesforce Case ID (18 characters) |
| file_name | `VARCHAR(255)` | NOT NULL | Original filename |
| content_type | `VARCHAR(100)` | | MIME type (e.g., image/png, application/pdf) |
| s3_key | `VARCHAR(500)` | NOT NULL | Full S3 path in our bucket |
| sync_status | `VARCHAR(20)` | DEFAULT `'pending'` | `pending` \| `syncing` \| `synced` \| `sync_failed` |
| sf_attachment_id | `VARCHAR(18)` | | Salesforce Cloud_Attachment__c ID after successful sync |
| sync_error | `TEXT` | | Error message if sync fails |
| created_at | `TIMESTAMPTZ` | DEFAULT `NOW()` | File upload timestamp |

### Constraints
- `attachment_id`: Format = `att_xxxx` (exactly 8 characters total)
- `sync_status`: Must be one of: `pending`, `syncing`, `synced`, `sync_failed`

### Sample Records

```json
Record 1:
{
  "attachment_id": "att_3j66",
  "case_id": "5001234567890ABCDE",
  "file_name": "product_photo.jpg",
  "s3_key": "salesforce-attachments/2024/12/product_photo_001.jpg",
  "sync_status": "pending",
  "sf_attachment_id": null,
  "sync_error": null,
  "created_at": "2025-12-29 17:29:55.990164+00:00"
}

Record 2:
{
  "attachment_id": "att_x74r",
  "case_id": "5001234567890ABCDE",
  "file_name": "repair_estimate.xlsx",
  "s3_key": "salesforce-attachments/2024/12/repair_estimate_001.xlsx",
  "sync_status": "pending",
  "sf_attachment_id": null,
  "sync_error": null,
  "created_at": "2025-12-29 17:29:55.990164+00:00"
}
```

**Total Records:** 18,954

---

## 6. case_reference_numbers

**Purpose:** Map MTP case reference numbers to Salesforce case IDs

### Schema

| Column | Type | Constraints | Description |
|:-------|:-----|:------------|:------------|
| **mtp_reference_number** | `VARCHAR(50)` | PK | MTP case reference number (e.g., `MTP-2024-001234`) |
| case_id | `VARCHAR(18)` | NOT NULL, FK | Salesforce Case ID (18 characters) |

### Sample Records

```json
Record 1:
{
  "mtp_reference_number": "MTP-2024-001234",
  "case_id": "5001234567890ABCDE"
}

Record 2:
{
  "mtp_reference_number": "MTP-2024-001235",
  "case_id": "5001234567890ABCDF"
}
```

**Total Records:** 5

---

## Summary

### 📊 Tables Overview

| Table | Primary Key | Auto-Generated Format | Total Records |
|:------|:------------|:---------------------|:-------------:|
| `cases` | `case_id` | From Salesforce (18 chars) | **300,182** |
| `case_drafts` | `draft_id` | 6 uppercase alphanumeric chars | **2** |
| `draft_attachments` | `attachment_id` | Manual (no auto-generation) | **0** |
| `case_comments` | `comment_id` | `cmt_` + 4 lowercase chars | **56,979** |
| `case_attachments` | `attachment_id` | `att_` + 4 lowercase chars | **18,954** |
| `case_reference_numbers` | `mtp_reference_number` | Manual entry (not auto) | **5** |

### ⚙️ Auto-Generation Functions

| Function | Format | Example Output | Character Set |
|:---------|:-------|:---------------|:--------------|
| `generate_draft_id()` | 6 chars uppercase | `R7VS3B` | A-Z, 2-9 (excludes 0,O,1,I) |
| `generate_comment_id()` | `cmt_` + 4 chars lowercase | `cmt_x7k2` | a-z, 2-9 (excludes 0,o,1,i) |
| `generate_attachment_id()` | `att_` + 4 chars lowercase | `att_c8m4` | a-z, 2-9 (excludes 0,o,1,i) |

### 🔒 Key Constraints

#### case_drafts
- ✓ `draft_id`: LENGTH = 6, NOT NULL, NOT EMPTY, UNIQUE
- ✓ `submission_status`: ENUM(`draft`, `submitting`, `submitted`, `submission_failed`)

#### case_comments
- ✓ `comment_id`: FORMAT = `cmt_xxxx` (8 chars total)
- ✓ `body`: MAX LENGTH = 5000 characters
- ✓ `sync_status`: ENUM(`pending`, `syncing`, `synced`, `sync_failed`)

#### case_attachments
- ✓ `attachment_id`: FORMAT = `att_xxxx` (8 chars total)
- ✓ `sync_status`: ENUM(`pending`, `syncing`, `synced`, `sync_failed`)
---
