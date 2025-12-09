# Phase 6: Data Migration and Validation

This directory contains scripts and tools for migrating data from SQL Server (WideWorldImporters OLTP and WideWorldImportersDW OLAP) to PostgreSQL.

## Overview

Phase 6 implements the Extract-Transform-Load (ETL) process for migrating data from SQL Server to PostgreSQL, along with comprehensive validation scripts to ensure data integrity.

## Directory Structure

```
data-migration/
├── 01-extract/           # Data extraction scripts (SQL Server to CSV/JSON)
├── 02-transform/         # Data transformation scripts (data type conversions)
├── 03-load/              # Data loading scripts (PostgreSQL bulk loading)
├── 04-validate/          # Validation scripts (row counts, integrity, relationships)
├── 05-performance/       # Performance testing and optimization scripts
├── docs/                 # Documentation and migration notes
├── config.py             # Configuration settings
├── run_migration.py      # Main migration orchestrator
└── README.md             # This file
```

## Prerequisites

1. SQL Server with WideWorldImporters and WideWorldImportersDW databases
2. PostgreSQL 15+ with PostGIS extension
3. Python 3.8+ with required packages:
   - pyodbc (SQL Server connectivity)
   - psycopg2 (PostgreSQL connectivity)
   - pandas (data manipulation)

4. PostgreSQL schemas created (run postgres-migration/install.sql and postgres-migration-dw/install.sql first)

## Quick Start

### 1. Install Python Dependencies

```bash
pip install pyodbc psycopg2-binary pandas tqdm
```

### 2. Configure Connection Settings

Edit `config.py` with your database connection details:

```python
SQL_SERVER_CONFIG = {
    'server': 'localhost',
    'database': 'WideWorldImporters',
    'username': 'sa',
    'password': 'your_password'
}

POSTGRES_CONFIG = {
    'host': 'localhost',
    'database': 'wideworldimporters',
    'user': 'webapi',
    'password': 'your_password',
    'port': 5432
}
```

### 3. Run the Migration

```bash
# Full migration (OLTP + OLAP)
python run_migration.py --full

# OLTP only
python run_migration.py --oltp

# OLAP only
python run_migration.py --olap

# Validation only
python run_migration.py --validate
```

## Migration Process

### Step 1: Extract Data from SQL Server

The extraction scripts export data from SQL Server tables to CSV files with proper encoding and data type handling.

```bash
python 01-extract/extract_oltp.py
python 01-extract/extract_olap.py
```

### Step 2: Transform Data

The transformation scripts handle data type conversions:
- `datetime2` → `timestamp`
- `nvarchar(n)` → `varchar(n)` or `text`
- `decimal(p,s)` → `numeric(p,s)`
- `varbinary(max)` → `bytea` (base64 encoded)
- `geography` → PostGIS geography type

```bash
python 02-transform/transform_data.py
```

### Step 3: Load Data into PostgreSQL

The loading scripts use PostgreSQL's COPY command for efficient bulk loading.

```bash
python 03-load/load_oltp.py
python 03-load/load_olap.py
```

### Step 4: Validate Migration

The validation scripts verify:
- Row counts match between source and target
- Data integrity (checksums, sample comparisons)
- Foreign key relationships are intact
- Sequences are properly seeded

```bash
python 04-validate/validate_migration.py
```

## Data Type Conversions

| SQL Server Type | PostgreSQL Type | Notes |
|-----------------|-----------------|-------|
| `datetime2` | `timestamp` | Microsecond precision preserved |
| `datetime` | `timestamp` | Millisecond precision |
| `date` | `date` | Direct mapping |
| `time` | `time` | Direct mapping |
| `nvarchar(n)` | `varchar(n)` | Unicode supported natively |
| `nvarchar(max)` | `text` | Unlimited length |
| `varchar(n)` | `varchar(n)` | Direct mapping |
| `varchar(max)` | `text` | Unlimited length |
| `decimal(p,s)` | `numeric(p,s)` | Direct mapping |
| `money` | `numeric(19,4)` | Fixed precision |
| `int` | `integer` | Direct mapping |
| `bigint` | `bigint` | Direct mapping |
| `smallint` | `smallint` | Direct mapping |
| `tinyint` | `smallint` | PostgreSQL has no tinyint |
| `bit` | `boolean` | 0/1 → false/true |
| `varbinary(max)` | `bytea` | Binary data |
| `geography` | `geography` | PostGIS extension |
| `hierarchyid` | `ltree` | Requires ltree extension |

## Temporal Tables

SQL Server temporal tables are migrated as:
- Main table with `validfrom` and `validto` columns
- Archive table (e.g., `tablename_archive`) for historical data
- Triggers to maintain temporal behavior

Both current and historical data are migrated to preserve the complete audit trail.

## Tables Migrated

### OLTP Database (WideWorldImporters)

**Application Schema:**
- People, Countries, StateProvinces, Cities
- DeliveryMethods, PaymentMethods, TransactionTypes
- SystemParameters, Logs

**Sales Schema:**
- Customers, CustomerCategories, BuyingGroups
- Orders, OrderLines, Invoices, InvoiceLines
- CustomerTransactions, SpecialDeals

**Warehouse Schema:**
- StockItems, StockGroups, StockItemStockGroups
- Colors, PackageTypes, StockItemHoldings
- StockItemTransactions, ColdRoomTemperatures, VehicleTemperatures

**Purchasing Schema:**
- Suppliers, SupplierCategories
- PurchaseOrders, PurchaseOrderLines
- SupplierTransactions

### OLAP Database (WideWorldImportersDW)

**Dimension Schema:**
- City, Customer, Date, Employee
- PaymentMethod, StockItem, Supplier, TransactionType

**Fact Schema:**
- Sale, Order, Purchase, Movement, Transaction, StockHolding

**Integration Schema:**
- ETL_Cutoff, Lineage
- Staging tables (populated during ETL runs)

## Performance Optimization

The migration uses several optimization techniques:

1. **Bulk Loading**: Uses PostgreSQL COPY command instead of INSERT
2. **Disabled Constraints**: Foreign keys disabled during load, re-enabled after
3. **Disabled Triggers**: Temporal triggers disabled during load
4. **Parallel Processing**: Multiple tables loaded concurrently
5. **Batch Processing**: Large tables processed in batches

## Troubleshooting

### Common Issues

1. **Connection Errors**
   - Verify SQL Server and PostgreSQL are running
   - Check firewall rules and port accessibility
   - Verify credentials in config.py

2. **Data Type Errors**
   - Check transformation logs for specific column issues
   - Verify PostGIS extension is installed for geography columns

3. **Foreign Key Violations**
   - Ensure tables are loaded in correct dependency order
   - Check for orphaned records in source data

4. **Sequence Issues**
   - Run sequence reset script after data load
   - Verify max ID values in migrated tables

### Logs

Migration logs are stored in `logs/` directory:
- `extract_YYYYMMDD_HHMMSS.log`
- `transform_YYYYMMDD_HHMMSS.log`
- `load_YYYYMMDD_HHMMSS.log`
- `validate_YYYYMMDD_HHMMSS.log`

## Validation Report

After migration, a validation report is generated with:
- Table-by-table row count comparison
- Data integrity check results
- Foreign key validation results
- Sequence validation results
- Performance metrics

## Support

For issues or questions, refer to:
- Phase 1 planning documents in `pg-migration` branch
- PostgreSQL migration guide: `POSTGRESQL_MIGRATION_GUIDE.md`
- Schema documentation in `postgres-migration/README.md`
