# Wide World Importers PostgreSQL Migration
## Phase 6: Data Migration and Validation

This directory contains scripts and documentation for migrating data from SQL Server to PostgreSQL for the Wide World Importers databases.

### Overview

Phase 6 handles the actual data migration from the SQL Server source databases to the PostgreSQL target databases. This includes both the OLTP (WideWorldImporters) and OLAP (WideWorldImportersDW) databases.

### Directory Structure

```
data-migration/
├── 01-extraction/           # SQL Server data extraction scripts
│   ├── 001-extract-oltp-data.sql    # OLTP extraction queries
│   ├── 002-extract-olap-data.sql    # OLAP extraction queries
│   └── 003-extract-data.sh          # Automated extraction script
├── 02-transformation/       # Data transformation scripts
│   └── 001-transform-oltp-data.py   # Python transformation script
├── 03-loading/              # PostgreSQL data loading scripts
│   ├── 001-load-oltp-data.sql       # OLTP COPY commands
│   ├── 002-load-olap-data.sql       # OLAP COPY commands
│   └── 003-update-sequences.sql     # Sequence value updates
├── 04-validation/           # Data validation scripts
│   ├── 001-validate-row-counts.sql      # Row count verification
│   ├── 002-validate-data-integrity.sql  # FK and constraint validation
│   ├── 003-validate-sequences.sql       # Sequence value validation
│   └── 004-validate-business-logic.sql  # Business logic tests
├── 05-performance/          # Performance testing and optimization
│   ├── 001-performance-tests.sql        # Performance benchmarks
│   └── 002-optimization-recommendations.md  # Tuning guide
└── README.md               # This file
```

### Prerequisites

Before running the migration:

1. **PostgreSQL Schema**: Ensure the PostgreSQL schema from Phases 2-5 is installed:
   - OLTP: Run `postgres-migration/install.sql`
   - OLAP: Run `postgres-migration-dw/install.sql`

2. **SQL Server Access**: Ensure SQL Server is running and accessible:
   ```bash
   sqlcmd -S localhost -U sa -P '$SQL_SERVER_PASSWORD' -C -Q "SELECT 1"
   ```

3. **PostgreSQL Access**: Ensure PostgreSQL is running and accessible:
   ```bash
   psql postgresql://webapi:Sp1d3rman#@localhost:5432/wideworldimporters -c "SELECT 1"
   ```

4. **Required Tools**:
   - `bcp` (SQL Server Bulk Copy Program)
   - `sqlcmd` (SQL Server command-line tool)
   - `psql` (PostgreSQL command-line tool)
   - Python 3.x with standard library

### Migration Process

#### Step 1: Extract Data from SQL Server

Run the extraction script to export data from SQL Server:

```bash
cd 01-extraction
chmod +x 003-extract-data.sh
./003-extract-data.sh
```

This creates CSV files in the `extracted_data/` directory with pipe-delimited data.

#### Step 2: Transform Data for PostgreSQL

Run the transformation script to convert data types and split temporal tables:

```bash
cd 02-transformation
python3 001-transform-oltp-data.py
```

This creates transformed files in the `transformed_data/` directory.

#### Step 3: Load Data into PostgreSQL

Load the OLTP data:

```bash
cd 03-loading
psql -d wideworldimporters -v data_dir="'../transformed_data'" -f 001-load-oltp-data.sql
```

Load the OLAP data:

```bash
psql -d wideworldimportersdw -v data_dir="'../transformed_data'" -f 002-load-olap-data.sql
```

Update sequences:

```bash
psql -d wideworldimporters -f 003-update-sequences.sql
```

#### Step 4: Validate Migration

Run validation scripts to verify the migration:

```bash
cd 04-validation

# Verify row counts
psql -d wideworldimporters -f 001-validate-row-counts.sql

# Verify data integrity
psql -d wideworldimporters -f 002-validate-data-integrity.sql

# Verify sequences
psql -d wideworldimporters -f 003-validate-sequences.sql

# Test business logic
psql -d wideworldimporters -f 004-validate-business-logic.sql
```

#### Step 5: Performance Testing

Run performance tests and review optimization recommendations:

```bash
cd 05-performance
psql -d wideworldimporters -f 001-performance-tests.sql
```

Review `002-optimization-recommendations.md` for tuning guidance.

### Data Type Conversions

The migration handles these SQL Server to PostgreSQL type conversions:

| SQL Server Type | PostgreSQL Type | Notes |
|-----------------|-----------------|-------|
| `datetime2` | `timestamp` | Preserves microsecond precision |
| `nvarchar(n)` | `varchar(n)` | Unicode support built-in |
| `nvarchar(max)` | `text` | Unlimited length |
| `decimal(p,s)` | `numeric(p,s)` | Exact numeric |
| `varbinary(max)` | `bytea` | Binary data |
| `geography` | `geography` | PostGIS extension |
| `bit` | `boolean` | 0/1 to false/true |
| `hierarchyid` | `ltree` | Hierarchical data |

### Temporal Tables

SQL Server temporal tables are migrated as:

- **Current data**: Main table (e.g., `sales.customers`)
- **Historical data**: Archive table (e.g., `sales.customers_archive`)

The transformation script splits temporal data based on the `ValidTo` column:
- Records with `ValidTo = '9999-12-31 23:59:59.9999999'` go to the main table
- Records with earlier `ValidTo` values go to the archive table

### Geography Data

Geography columns are handled using PostGIS:

1. Extraction converts geography to WKT (Well-Known Text) format
2. Loading uses `ST_GeogFromText()` to convert WKT back to geography

### Known Issues and Resolutions

#### Issue 1: Binary Data Encoding

**Problem**: SQL Server binary data (varbinary) exports as hex strings with `0x` prefix.

**Resolution**: The transformation script converts `0x...` format to PostgreSQL `\x...` format.

#### Issue 2: NULL Handling in CSV

**Problem**: Empty strings vs NULL values in CSV exports.

**Resolution**: Use pipe delimiter (`|`) and explicit NULL handling in COPY commands.

#### Issue 3: Temporal Table Splitting

**Problem**: SQL Server temporal tables export all history in one result set.

**Resolution**: Transformation script splits data based on `ValidTo` timestamp.

#### Issue 4: Geography Column Loading

**Problem**: PostgreSQL COPY cannot directly parse WKT geography data.

**Resolution**: Use staging tables and `ST_GeogFromText()` for conversion.

### Performance Considerations

1. **Bulk Loading**: Use `COPY` instead of `INSERT` for large tables
2. **Disable Triggers**: Set `session_replication_role = 'replica'` during load
3. **Increase work_mem**: Set `work_mem = '256MB'` for better COPY performance
4. **Parallel Loading**: Load independent tables in parallel
5. **Index Rebuilding**: Consider dropping and recreating indexes for large tables

### Rollback Procedure

If migration fails, restore from backup or truncate tables:

```sql
-- Truncate all tables (in dependency order)
TRUNCATE sales.invoicelines CASCADE;
TRUNCATE sales.invoices CASCADE;
TRUNCATE sales.orderlines CASCADE;
TRUNCATE sales.orders CASCADE;
-- ... continue for all tables
```

### Support

For issues with this migration:

1. Check the validation script output for specific errors
2. Review PostgreSQL logs for COPY errors
3. Verify source data in SQL Server matches expected format
4. Ensure all prerequisites are met before running migration

### Related Documentation

- Phase 1: Assessment and Planning (`pg-migration` branch)
- Phase 2: OLTP Schema Migration (`postgres-migration/`)
- Phase 3: OLTP Code Migration (`postgres-migration/`)
- Phase 4: OLAP Schema Migration (`postgres-migration-dw/`)
- Phase 5: ETL and Analytics Migration (`postgres-migration/`)
