# Wide World Importers DW - PostgreSQL Migration (Phase 4)

This directory contains the PostgreSQL migration scripts for the Wide World Importers Data Warehouse (OLAP) schema.

## Overview

Phase 4 migrates the WideWorldImportersDW data warehouse schema from SQL Server to PostgreSQL. This includes dimension tables, fact tables, staging tables for ETL, and integration tables for lineage tracking.

## Schema Structure

### Schemas
- **dimension**: Contains all dimension tables for the star schema
- **fact**: Contains all fact tables with partitioning
- **integration**: Contains staging tables and ETL tracking tables

### Dimension Tables (8 tables)
| Table | Description | SCD Type |
|-------|-------------|----------|
| dimension.city | City dimension with geography | Type 2 |
| dimension.customer | Customer dimension | Type 2 |
| dimension.date | Date dimension (calendar/fiscal) | Type 0 |
| dimension.employee | Employee dimension | Type 2 |
| dimension.payment_method | Payment method dimension | Type 2 |
| dimension.stock_item | Stock item dimension | Type 2 |
| dimension.supplier | Supplier dimension | Type 2 |
| dimension.transaction_type | Transaction type dimension | Type 2 |

### Fact Tables (6 tables)
| Table | Description | Partitioned |
|-------|-------------|-------------|
| fact.sale | Sales transactions | Yes (by invoice_date_key) |
| fact.order | Customer orders | Yes (by order_date_key) |
| fact.purchase | Purchase orders | Yes (by date_key) |
| fact.movement | Stock movements | Yes (by date_key) |
| fact.transaction | Financial transactions | Yes (by date_key) |
| fact.stock_holding | Current stock holdings | No |

### Staging Tables (13 tables)
All staging tables are created as UNLOGGED tables for ETL performance (equivalent to SQL Server's memory-optimized tables with SCHEMA_ONLY durability).

### Integration Tables
- **integration.lineage**: Tracks ETL load history
- **integration.etl_cutoff**: Tracks last successful ETL cutoff times

## Data Type Mappings

| SQL Server | PostgreSQL | Notes |
|------------|------------|-------|
| datetime2 | timestamp | |
| nvarchar(n) | varchar(n) | |
| nvarchar(max) | text | |
| decimal(p,s) | numeric(p,s) | |
| bigint | bigint | |
| bit | boolean | |
| varbinary(max) | bytea | |
| sys.geography | geography | Requires PostGIS |
| sysname | varchar(128) | |
| IDENTITY | SERIAL/BIGSERIAL | Or sequences |

## SQL Server Features - PostgreSQL Equivalents

### Partitioning
- **SQL Server**: Partition function (PF_Date) and partition scheme (PS_Date)
- **PostgreSQL**: Native table partitioning by RANGE on date columns

### Memory-Optimized Tables
- **SQL Server**: `MEMORY_OPTIMIZED = ON, DURABILITY = SCHEMA_ONLY`
- **PostgreSQL**: `UNLOGGED` tables (no WAL logging)

### Clustered Columnstore Indexes
- **SQL Server**: Clustered columnstore indexes on fact tables
- **PostgreSQL**: B-tree indexes + BRIN indexes for date columns (PostgreSQL doesn't support columnstore)

### Sequences for Surrogate Keys
- **SQL Server**: `NEXT VALUE FOR [Sequences].[KeyName]`
- **PostgreSQL**: `nextval('sequences.key_name')`

## Installation

### Prerequisites
1. PostgreSQL 15+ with PostGIS extension
2. OLTP schema (postgres-migration) must be installed first

### Install the OLAP Schema
```bash
cd postgres-migration-dw
psql -d wideworldimporters -f install.sql
```

### Validate the Installation
```bash
psql -d wideworldimporters -f 99-tests/001-validate-olap-schema.sql
```

## Directory Structure

```
postgres-migration-dw/
├── 01-schemas/           # Schema creation
├── 02-sequences/         # Surrogate key sequences
├── 03-dimension-tables/  # Dimension table definitions
├── 04-fact-tables/       # Fact table definitions with partitions
├── 05-staging-tables/    # ETL staging tables (UNLOGGED)
├── 06-integration-tables/# Lineage and ETL cutoff tables
├── 07-indexes/           # Index definitions
├── 08-constraints/       # Foreign key constraints
├── 99-tests/             # Validation scripts
├── install.sql           # Master installation script
└── README.md             # This file
```

## Next Steps

After Phase 4 is complete, Phase 5 (ETL Migration) will migrate the stored procedures that populate the data warehouse from the OLTP database.
