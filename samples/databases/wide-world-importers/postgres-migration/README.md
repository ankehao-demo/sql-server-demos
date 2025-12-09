# Wide World Importers PostgreSQL Migration - Phase 2: OLTP Schema

This directory contains the PostgreSQL schema migration for the Wide World Importers OLTP database, originally designed for SQL Server.

## Overview

Phase 2 migrates the complete OLTP database schema from SQL Server to PostgreSQL, including:

- 5 database schemas (Application, Warehouse, Sales, Purchasing, Sequences)
- 26 sequences for ID generation
- 32 main tables across all schemas
- 17 archive tables for temporal table support
- 17 temporal triggers for automatic history tracking
- 70+ foreign key constraints
- 100+ indexes for performance optimization

## Directory Structure

```
postgres-migration/
├── install.sql                    # Master installation script
├── 01-schemas/                    # Schema and extension creation
│   └── 001-create-schemas.sql
├── 02-sequences/                  # Sequence definitions
│   └── 001-create-sequences.sql
├── 03-tables/                     # Table definitions
│   ├── 001-application-tables.sql
│   ├── 002-warehouse-tables.sql
│   ├── 003-sales-tables.sql
│   └── 004-purchasing-tables.sql
├── 04-archive-tables/             # Archive tables for temporal support
│   └── 001-archive-tables.sql
├── 05-triggers/                   # Temporal table triggers
│   └── 001-temporal-triggers.sql
├── 06-constraints/                # Foreign key constraints
│   └── 001-foreign-keys.sql
├── 07-indexes/                    # Performance indexes
│   └── 001-indexes.sql
└── 08-tests/                      # Validation test scripts
    ├── 001-test-schema.sql
    └── 002-test-temporal-triggers.sql
```

## Prerequisites

- PostgreSQL 15 or later
- PostGIS extension (for geography/spatial data types)
- A database created for the migration

## Installation

### Option 1: Using the master install script

```bash
cd postgres-migration
psql -d wideworldimporters -f install.sql
```

### Option 2: Running individual scripts

```bash
psql -d wideworldimporters -f 01-schemas/001-create-schemas.sql
psql -d wideworldimporters -f 02-sequences/001-create-sequences.sql
psql -d wideworldimporters -f 03-tables/001-application-tables.sql
psql -d wideworldimporters -f 03-tables/002-warehouse-tables.sql
psql -d wideworldimporters -f 03-tables/003-sales-tables.sql
psql -d wideworldimporters -f 03-tables/004-purchasing-tables.sql
psql -d wideworldimporters -f 04-archive-tables/001-archive-tables.sql
psql -d wideworldimporters -f 05-triggers/001-temporal-triggers.sql
psql -d wideworldimporters -f 06-constraints/001-foreign-keys.sql
psql -d wideworldimporters -f 07-indexes/001-indexes.sql
```

## Validation

After installation, run the test scripts to validate the migration:

```bash
psql -d wideworldimporters -f 08-tests/001-test-schema.sql
psql -d wideworldimporters -f 08-tests/002-test-temporal-triggers.sql
```

## Data Type Conversions

The following SQL Server to PostgreSQL data type mappings were applied:

| SQL Server | PostgreSQL |
|------------|------------|
| datetime2 | timestamp |
| nvarchar(n) | varchar(n) |
| nvarchar(max) | text |
| decimal(p,s) | numeric(p,s) |
| bigint | bigint |
| int | integer |
| bit | boolean |
| varbinary(max) | bytea |
| sys.geography | geography (PostGIS) |
| IDENTITY | SERIAL/BIGSERIAL or sequence DEFAULT |

## Temporal Tables

SQL Server's built-in temporal tables (SYSTEM_VERSIONING) are implemented in PostgreSQL using:

1. Archive tables (e.g., `warehouse.colors_archive`) that mirror the main table structure
2. BEFORE triggers on INSERT, UPDATE, and DELETE operations
3. Automatic maintenance of `ValidFrom` and `ValidTo` columns

The triggers ensure:
- On INSERT: `ValidFrom` is set to current timestamp, `ValidTo` to infinity
- On UPDATE: Old row is copied to archive with `ValidTo` = current timestamp
- On DELETE: Row is copied to archive with `ValidTo` = current timestamp

## Memory-Optimized Tables

SQL Server memory-optimized tables (`Warehouse.ColdRoomTemperatures`, `Warehouse.VehicleTemperatures`) are converted to regular PostgreSQL tables with BIGSERIAL for identity columns.

## Computed Columns

SQL Server computed columns are implemented using PostgreSQL's `GENERATED ALWAYS AS ... STORED` syntax where supported (e.g., `SearchName` in `Application.People`, `IsFinalized` in transaction tables).

## Next Steps

After completing Phase 2 (Schema Migration), proceed to:

- **Phase 3**: OLTP Code Migration (stored procedures, functions, views)
- **Phase 4**: Data Migration
- **Phase 5**: ETL Migration
