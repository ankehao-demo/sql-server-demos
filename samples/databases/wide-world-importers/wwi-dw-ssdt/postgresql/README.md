# Wide World Importers Data Warehouse - PostgreSQL Migration

## Phase 4: OLAP Schema Migration

This directory contains the PostgreSQL schema migration scripts for the Wide World Importers Data Warehouse (WideWorldImportersDW). These scripts convert the SQL Server OLAP schema to PostgreSQL, maintaining the star schema design pattern with dimension and fact tables.

## Directory Structure

```
postgresql/
├── schemas/           # Schema creation scripts
├── sequences/         # Sequence definitions for surrogate keys
├── dimension/         # Dimension table definitions
├── fact/             # Fact table definitions (with partitioning)
├── integration/      # ETL staging tables and lineage tracking
└── README.md         # This file
```

## Execution Order

Run the scripts in the following order:

1. `schemas/00_create_schemas.sql` - Creates the four main schemas
2. `sequences/01_create_sequences.sql` - Creates sequences for surrogate keys
3. `dimension/02_dimension_*.sql` - Creates all dimension tables
4. `fact/03_fact_*.sql` - Creates all fact tables with partitioning
5. `integration/04_integration_*.sql` - Creates ETL staging tables

## SQL Server to PostgreSQL Conversion Notes

### Data Type Mappings

| SQL Server Type | PostgreSQL Type | Notes |
|----------------|-----------------|-------|
| `datetime2` | `timestamp` | No timezone by default |
| `nvarchar(n)` | `varchar(n)` | PostgreSQL varchar is already Unicode |
| `decimal(p,s)` | `decimal(p,s)` | Same syntax |
| `bigint` | `bigint` | Same type |
| `int` | `integer` | Same type |
| `bit` | `boolean` | TRUE/FALSE instead of 1/0 |
| `varbinary(max)` | `bytea` | Binary data |
| `geography` | `geography` | Requires PostGIS extension |

### SQL Server-Specific Features Converted

#### 1. Sequences
SQL Server sequences using `NEXT VALUE FOR [Sequences].[SequenceName]` are converted to PostgreSQL sequences with `nextval('sequences.sequence_name')` or `GENERATED ALWAYS AS IDENTITY`.

#### 2. Partitioning
SQL Server partition functions and schemes (`PF_Date`, `PS_Date`) are converted to PostgreSQL native range partitioning:

**SQL Server:**
```sql
CREATE PARTITION FUNCTION PF_Date (DATE) AS RANGE RIGHT FOR VALUES (...)
CREATE PARTITION SCHEME PS_Date AS PARTITION PF_Date ALL TO ([USERDATA])
CREATE TABLE ... ON PS_Date([Date Key])
```

**PostgreSQL:**
```sql
CREATE TABLE fact.sale (...) PARTITION BY RANGE (invoice_date_key);
CREATE TABLE fact.sale_y2016 PARTITION OF fact.sale FOR VALUES FROM ('2016-01-01') TO ('2017-01-01');
```

#### 3. Memory-Optimized Tables
SQL Server In-Memory OLTP tables (`MEMORY_OPTIMIZED = ON, DURABILITY = SCHEMA_ONLY`) are converted to PostgreSQL `UNLOGGED` tables for similar performance characteristics during ETL operations.

**SQL Server:**
```sql
CREATE TABLE [Integration].[Customer_Staging] (...) 
WITH (MEMORY_OPTIMIZED = ON, DURABILITY = SCHEMA_ONLY)
```

**PostgreSQL:**
```sql
CREATE UNLOGGED TABLE integration.customer_staging (...)
```

#### 4. Clustered Columnstore Indexes
SQL Server Clustered Columnstore Indexes (CCX) on fact tables have no direct PostgreSQL equivalent. For similar analytical performance, consider:
- Using columnar storage extensions (Citus, TimescaleDB)
- Creating appropriate B-tree indexes on frequently queried columns
- Using materialized views for common aggregations

#### 5. Extended Properties
SQL Server `sp_addextendedproperty` calls are converted to PostgreSQL `COMMENT ON` statements.

#### 6. Identity Columns
SQL Server `IDENTITY(1,1)` columns are converted to PostgreSQL `GENERATED ALWAYS AS IDENTITY` or sequence-based defaults.

### Schema Design

The data warehouse follows a star schema pattern:

**Dimension Tables:**
- `dimension.city` - City locations with geography data
- `dimension.customer` - Customer information (SCD Type 2)
- `dimension.date` - Date dimension with extensive calendar attributes
- `dimension.employee` - Employee information
- `dimension.payment_method` - Payment method types
- `dimension.stock_item` - Product/stock item details
- `dimension.supplier` - Supplier information
- `dimension.transaction_type` - Transaction type classifications

**Fact Tables:**
- `fact.sale` - Invoiced sales (partitioned by invoice date)
- `fact.order` - Customer orders (partitioned by order date)
- `fact.purchase` - Stock purchases (partitioned by date)
- `fact.movement` - Stock movements (partitioned by date)
- `fact.transaction` - Financial transactions (partitioned by date)
- `fact.stock_holding` - Current stock levels (not partitioned)

**Integration Tables:**
- Staging tables for each dimension and fact table
- Lineage tracking for ETL audit trail
- ETL cutoff times for incremental loads

### Prerequisites

Before running these scripts, ensure:

1. PostgreSQL 12+ is installed (for native partitioning support)
2. PostGIS extension is available (for geography columns)
3. The target database exists

```sql
-- Enable PostGIS extension
CREATE EXTENSION IF NOT EXISTS postgis;
```

### Running the Migration

```bash
# Connect to PostgreSQL and run scripts in order
psql -h localhost -U postgres -d wideworldimportersdw -f schemas/00_create_schemas.sql
psql -h localhost -U postgres -d wideworldimportersdw -f sequences/01_create_sequences.sql
# ... continue with dimension, fact, and integration scripts
```

Or use the master script:
```bash
psql -h localhost -U postgres -d wideworldimportersdw -f 00_run_all.sql
```

## Phase 5 Dependencies

Phase 5 (ETL and Analytics Migration) depends on this phase being completed. The integration staging tables and final dimension/fact tables must exist before ETL procedures can be migrated.
