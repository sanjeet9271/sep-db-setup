# SEP Database Setup

SQL scripts and tools for setting up and managing the SEP database.

## 📁 Repository Structure

```
SEP-Database-Setup/
├── Table_Scripts/          # SQL table creation scripts
├── Data/                   # CSV data files (git ignored)
├── scripts/
│   ├── db_config.py       # Database config loader
│   ├── setup_env.py       # Interactive credential setup
│   ├── schema_check/      # Schema inspection tool
│   ├── sql_table_scripts/ # SQL scripts (creation & modification)
│   ├── data_upload/       # Data upload scripts
│   └── testing_db/        # Database testing scripts
└── .env                    # Your credentials (git ignored)
```

## 🔧 Quick Setup

### 1. Install Dependencies
```bash
pip install -r requirements.txt
```

### 2. Configure Database

**Option A: Interactive Setup (Easiest)**
```bash
python scripts/setup_env.py
```

**Option B: Manual Setup**

Create a `.env` file in the project root:
```bash
DB_HOST=your-database-host.rds.amazonaws.com
DB_PORT=5432
DB_NAME=postgres
DB_USER=dbadmin
DB_PASSWORD=your_password_here
```

**Note:** VPN connection required to access the database.

### 3. Test Connection
```bash
python scripts/schema_check/schema_check.py
```

---

## 📋 Tables (12 Total)

### Core Business Tables
1. **account** - Account/Dealer master data
2. **contact** - Contact information
3. **technician** - Technician certifications
4. **inventory** - Inventory master data
5. **service__parts** - Service parts catalog
6. **employee** - Employee information

### Case Management Tables
7. **cases** - Salesforce cases
8. **case_drafts** - Draft case submissions
9. **case_comments** - Case comments
10. **case_attachments** - Case attachments
11. **draft_attachments** - Draft attachments
12. **case_reference_numbers** - MTP reference mapping

---

## 🔄 Execution Order

### Phase 1: Base Tables
```
1. create_account_table.sql
2. create_service_parts_table.sql
3. create_employee_table.sql
```

### Phase 2: Account Dependencies
```
4. create_contact_table.sql
5. create_technician_table.sql
6. create_inventory_table.sql
```

### Phase 3: Case Tables
```
7. create_cases_table.sql
8. create_case_drafts_table.sql
```

### Phase 4: Case Dependencies
```
9. create_case_comments_table.sql
10. create_case_attachments_table.sql
11. create_draft_attachments_table.sql
12. create_case_reference_numbers_table.sql
```

---

## 🚀 Usage

### Python Database Connection
```python
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent / 'scripts'))

from db_config import load_db_config
import psycopg2

config = load_db_config()  # Auto-loads from .env or dbConfig.json
conn = psycopg2.connect(**config)
```

### psql Command
```bash
psql -h HOST -p 5432 -U USER -d DATABASE -f Table_Scripts/create_account_table.sql
```

---

## 🔒 Security

- `.env` and `*.csv` files are git-ignored
- Never commit credentials to git
- Always use VPN when accessing the database
- Use `python scripts/setup_env.py` for secure credential setup

---

**Last Updated:** January 8, 2026  
**Status:** ✅ All scripts up-to-date
