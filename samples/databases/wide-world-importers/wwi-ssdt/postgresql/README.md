# Wide World Importers PostgreSQL Migration Scripts

This directory contains the PostgreSQL migration scripts for the Wide World Importers database, migrated from SQL Server.

## Overview

The migration is organized into three phases:

- **Phase 2**: OLTP Schema Migration (WideWorldImporters transactional database)
- **Phase 3**: OLTP Code Migration (Stored procedures, functions, and security)
- **Phase 4**: OLAP Schema Migration (WideWorldImportersDW data warehouse)

## Prerequisites

- PostgreSQL 15 or later
- PostGIS extension (for spatial data)
- pg_partman extension (for table partitioning)
- pgcrypto extension (for password hashing)

## Directory Structure

```
postgresql/
├── run_migration.sql           # Master script to run all migrations
├── phase2-oltp-schema/         # OLTP schema migration scripts
│   ├── 001_create_schemas.sql  # Create schemas and extensions
│   ├── 002_create_sequences.sql # Create ID sequences
│   ├── 003_application_tables.sql # Application schema tables
│   ├── 004_sales_tables.sql    # Sales schema tables
│   ├── 005_purchasing_tables.sql # Purchasing schema tables
│   ├── 006_warehouse_tables.sql # Warehouse schema tables
│   ├── 007_foreign_keys.sql    # Foreign key constraints
│   └── 008_temporal_triggers.sql # Temporal table triggers
├── phase3-oltp-code/           # OLTP code migration scripts
│   ├── 001_website_functions.sql # Website functions
│   ├── 002_website_procedures.sql # Website stored procedures
│   ├── 003_row_level_security.sql # Row-level security policies
│   └── 004_data_loading_simulation.sql # Data loading simulation
└── phase4-olap-schema/         # OLAP schema migration scripts
    ├── 001_create_dw_schemas.sql # Data warehouse schemas
    ├── 002_dimension_tables.sql # Dimension tables
    ├── 003_fact_tables.sql     # Fact tables
    ├── 004_staging_tables.sql  # ETL staging tables
    └── 005_integration_procedures.sql # ETL procedures
```

## Running the Migration

### Option 1: Run All Phases

Connect to your PostgreSQL database and run the master migration script:

```bash
psql -h localhost -U postgres -d wideworldimporters -f run_migration.sql
```

### Option 2: Run Individual Phases

You can run each phase separately:

```bash
# Phase 2: OLTP Schema
psql -h localhost -U postgres -d wideworldimporters -f phase2-oltp-schema/001_create_schemas.sql
psql -h localhost -U postgres -d wideworldimporters -f phase2-oltp-schema/002_create_sequences.sql
# ... continue with remaining files in order

# Phase 3: OLTP Code
psql -h localhost -U postgres -d wideworldimporters -f phase3-oltp-code/001_website_functions.sql
# ... continue with remaining files in order

# Phase 4: OLAP Schema
psql -h localhost -U postgres -d wideworldimporters -f phase4-olap-schema/001_create_dw_schemas.sql
# ... continue with remaining files in order
```

## Key Migration Decisions

### Data Type Mappings

| SQL Server | PostgreSQL |
|------------|------------|
| datetime2 | timestamp |
| nvarchar(n) | varchar(n) |
| decimal(p,s) | numeric(p,s) |
| bigint | bigint |
| varbinary(max) | bytea |
| geography | geometry (PostGIS) |
| bit | boolean |

### Temporal Tables

SQL Server temporal tables are implemented using:
- History tables (e.g., `people_archive`)
- Triggers that copy old records to history tables on UPDATE/DELETE
- `valid_from` and `valid_to` columns for versioning

### Row-Level Security

SQL Server RLS is implemented using PostgreSQL RLS policies:
- Sales territory-based access control
- Roles for each sales territory (e.g., `great_lakes_sales`)
- Policy functions that check user role membership

### Sequences

SQL Server sequences are converted to PostgreSQL sequences:
- All sequences are in the `sequences` schema
- Used with `nextval()` function instead of `NEXT VALUE FOR`

## Testing

After running the migration:

1. Verify schema structure:
```sql
SELECT schema_name FROM information_schema.schemata WHERE schema_name IN ('application', 'sales', 'purchasing', 'warehouse', 'dimension', 'fact', 'integration');
```

2. Verify tables were created:
```sql
SELECT table_schema, table_name FROM information_schema.tables WHERE table_schema IN ('application', 'sales', 'purchasing', 'warehouse', 'dimension', 'fact', 'integration') ORDER BY table_schema, table_name;
```

3. Verify temporal triggers:
```sql
SELECT trigger_name, event_object_table FROM information_schema.triggers WHERE trigger_schema IN ('application', 'sales', 'purchasing', 'warehouse');
```

4. Test row-level security:
```sql
-- As a user with great_lakes_sales role
SET ROLE great_lakes_sales;
SELECT COUNT(*) FROM sales.customers; -- Should only see Great Lakes customers
RESET ROLE;
```

## Notes

- The Date dimension is pre-populated with dates from 2013-01-01 to 2025-12-31
- ETL procedures use SCD Type 2 for dimension tables
- Stock Holding fact table uses snapshot replacement strategy
- All procedures include comprehensive error handling
