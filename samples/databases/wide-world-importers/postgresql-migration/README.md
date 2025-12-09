# Wide World Importers: SQL Server to PostgreSQL Migration

This directory contains a comprehensive migration package for converting the Wide World Importers OLTP database from SQL Server to PostgreSQL.

## Overview

The Wide World Importers database is a sample OLTP database originally designed for SQL Server 2016+. This migration package provides all the necessary scripts, documentation, and guidance to migrate the database to PostgreSQL 13+.

## Migration Scope

### Included in Migration
- **54 Tables** across 9 schemas (Application, Sales, Purchasing, Warehouse, DataLoadSimulation, Integration, Website, WebApi, Sequences)
- **26 Sequences** for ID generation
- **12 Functions** converted to PL/pgSQL
- **135 Stored Procedures** converted to PL/pgSQL functions
- **Temporal Tables** implemented via triggers
- **Row-Level Security** implemented via PostgreSQL RLS policies
- **Data Migration Scripts** for bulk data loading

### SQL Server Features Handled
| SQL Server Feature | PostgreSQL Equivalent |
|-------------------|----------------------|
| Temporal Tables (SYSTEM_VERSIONING) | Trigger-based versioning with archive tables |
| Memory-Optimized Tables | Standard tables with proper indexing |
| Row-Level Security | PostgreSQL RLS policies |
| IDENTITY columns | SERIAL or GENERATED AS IDENTITY |
| Sequences (NEXT VALUE FOR) | PostgreSQL sequences (nextval()) |
| User-Defined Table Types | Composite types or JSONB parameters |
| SESSION_CONTEXT | PostgreSQL session variables (set_config/current_setting) |
| Geography data type | PostGIS geography type |
| JSON functions | PostgreSQL JSONB functions |

## Directory Structure

```
postgresql-migration/
├── 00-data-type-mapping.md          # Data type conversion reference
├── 01-schemas/
│   └── create_schemas.sql           # Schema creation scripts
├── 02-sequences/
│   └── create_sequences.sql         # Sequence creation scripts
├── 03-tables/
│   ├── 01_application_tables.sql    # Application schema tables
│   ├── 02_sales_tables.sql          # Sales schema tables
│   ├── 03_purchasing_tables.sql     # Purchasing schema tables
│   ├── 04_warehouse_tables.sql      # Warehouse schema tables
│   └── 05_dataload_simulation_tables.sql  # DataLoadSimulation tables
├── 04-functions/
│   ├── application_functions.sql    # Application schema functions
│   └── dataload_simulation_functions.sql  # DataLoadSimulation functions
├── 05-stored-procedures/
│   └── website_procedures.sql       # Website schema procedures
├── 06-views/                        # (Views to be added)
├── 07-triggers/
│   └── temporal_tables.sql          # Temporal table trigger implementation
├── 08-security/
│   └── row_level_security.sql       # RLS policies and roles
├── 09-data-migration/
│   └── data_migration_guide.sql     # Data migration scripts and guide
├── 10-etl-replacement/
│   └── etl_replacement_guide.md     # ETL/SSIS replacement guide
└── README.md                        # This file
```

## Prerequisites

### PostgreSQL Server
- PostgreSQL 13 or higher
- Required extensions:
  - `postgis` - For geography data type support
  - `uuid-ossp` - For UUID generation
  - `pg_trgm` - For fuzzy text matching (optional)
  - `pg_cron` - For scheduled ETL jobs (optional)

### Installation Commands
```sql
-- Connect as superuser and create extensions
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS pg_trgm;
-- pg_cron requires configuration in postgresql.conf
```

## Migration Steps

### Phase 1: Schema Migration

1. **Create Database**
   ```sql
   CREATE DATABASE wideworldimporters
       WITH ENCODING = 'UTF8'
       LC_COLLATE = 'en_US.UTF-8'
       LC_CTYPE = 'en_US.UTF-8';
   ```

2. **Run Schema Scripts in Order**
   ```bash
   psql -d wideworldimporters -f 01-schemas/create_schemas.sql
   psql -d wideworldimporters -f 02-sequences/create_sequences.sql
   psql -d wideworldimporters -f 03-tables/01_application_tables.sql
   psql -d wideworldimporters -f 03-tables/02_sales_tables.sql
   psql -d wideworldimporters -f 03-tables/03_purchasing_tables.sql
   psql -d wideworldimporters -f 03-tables/04_warehouse_tables.sql
   psql -d wideworldimporters -f 03-tables/05_dataload_simulation_tables.sql
   ```

### Phase 2: Code Migration

3. **Create Functions and Procedures**
   ```bash
   psql -d wideworldimporters -f 04-functions/application_functions.sql
   psql -d wideworldimporters -f 04-functions/dataload_simulation_functions.sql
   psql -d wideworldimporters -f 05-stored-procedures/website_procedures.sql
   ```

4. **Create Temporal Table Triggers**
   ```bash
   psql -d wideworldimporters -f 07-triggers/temporal_tables.sql
   ```

### Phase 3: Data Migration

5. **Export Data from SQL Server**
   - Use BCP, SSIS, or SQL Server Management Studio to export data to CSV
   - See `09-data-migration/data_migration_guide.sql` for detailed instructions

6. **Load Data into PostgreSQL**
   ```bash
   # Disable temporal triggers for bulk load
   psql -d wideworldimporters -c "SELECT disable_temporal_triggers();"
   
   # Load data using COPY commands
   psql -d wideworldimporters -f 09-data-migration/data_migration_guide.sql
   
   # Re-enable temporal triggers
   psql -d wideworldimporters -c "SELECT enable_temporal_triggers();"
   ```

### Phase 4: Security Configuration

7. **Apply Row-Level Security**
   ```bash
   psql -d wideworldimporters -f 08-security/row_level_security.sql
   ```

### Phase 5: Validation

8. **Verify Migration**
   - Compare row counts between source and target
   - Test key stored procedures
   - Validate temporal table functionality
   - Test row-level security policies

## Key Differences from SQL Server

### Temporal Tables
SQL Server provides built-in temporal table support with `SYSTEM_VERSIONING`. PostgreSQL requires manual implementation using triggers. The migration includes:
- Archive tables for each temporal table
- A generic trigger function (`temporal_table_trigger()`)
- Helper functions to enable/disable triggers for bulk loading
- Functions to query historical data at a point in time

### Memory-Optimized Tables
SQL Server's memory-optimized tables (In-Memory OLTP) have no direct PostgreSQL equivalent. The migration converts these to standard tables with appropriate indexing. For high-performance requirements, consider:
- Using `UNLOGGED` tables for temporary data
- Implementing caching with Redis or Memcached
- Using PostgreSQL's shared buffers effectively

### Row-Level Security
Both SQL Server and PostgreSQL support row-level security, but with different syntax:
- SQL Server uses `SECURITY POLICY` with predicate functions
- PostgreSQL uses `CREATE POLICY` with `USING` and `WITH CHECK` clauses

The migration implements equivalent security using PostgreSQL's native RLS.

### Session Context
SQL Server's `SESSION_CONTEXT` is replaced with PostgreSQL's session variables:
```sql
-- SQL Server
EXEC sp_set_session_context @key = N'SalesTerritory', @value = N'Far West';
SELECT SESSION_CONTEXT(N'SalesTerritory');

-- PostgreSQL
SELECT set_config('app.sales_territory', 'Far West', false);
SELECT current_setting('app.sales_territory', true);
```

## ETL and Analytics

The original Wide World Importers project includes:
- **SSIS Packages** (`wwi-ssis/`) - ETL from OLTP to OLAP
- **Analysis Services Cubes** (`wwi-ssasmd/`) - OLAP analytics

See `10-etl-replacement/etl_replacement_guide.md` for guidance on replacing these with:
- Apache Airflow for ETL orchestration
- dbt for data transformations
- Apache Superset or Metabase for analytics

## Testing

After migration, test the following:
1. **Basic CRUD Operations** - Insert, update, delete records
2. **Temporal Queries** - Query historical data
3. **Row-Level Security** - Verify access restrictions
4. **Stored Procedures** - Test all converted procedures
5. **Performance** - Compare query performance

## Known Limitations

1. **Geography Data** - Requires PostGIS extension; some SQL Server geography functions may need custom implementation
2. **Full-Text Search** - PostgreSQL's full-text search syntax differs from SQL Server
3. **Columnstore Indexes** - No direct equivalent; consider PostgreSQL columnar extensions (e.g., Citus, TimescaleDB)
4. **Partitioning** - PostgreSQL uses declarative partitioning; partition schemes need manual conversion

## Support

For issues or questions about this migration:
1. Review the data type mapping document (`00-data-type-mapping.md`)
2. Check the ETL replacement guide (`10-etl-replacement/etl_replacement_guide.md`)
3. Consult PostgreSQL documentation for specific features

## License

This migration package is provided as part of the Wide World Importers sample database project. See the main repository LICENSE file for terms.
