# Wide World Importers PostgreSQL Migration - Phase 2: OLTP Schema

This directory contains the PostgreSQL schema migration for the Wide World Importers OLTP database, converted from SQL Server.

## Directory Structure

```
postgres-migration/
├── 00-extensions/          # PostgreSQL extensions (PostGIS, uuid-ossp, pg_trgm)
├── 01-schemas/             # Schema definitions (application, purchasing, sales, warehouse, sequences)
├── 02-sequences/           # Sequence definitions (converted from SQL Server SEQUENCE objects)
├── 03-tables/              # Table definitions organized by schema
│   ├── application/        # Application schema tables (People, Cities, Countries, etc.)
│   ├── purchasing/         # Purchasing schema tables (Suppliers, PurchaseOrders, etc.)
│   ├── sales/              # Sales schema tables (Customers, Orders, Invoices, etc.)
│   └── warehouse/          # Warehouse schema tables (StockItems, Colors, etc.)
├── 04-temporal-triggers/   # Trigger functions for temporal table versioning
├── 05-indexes/             # Additional indexes (if needed)
└── 06-constraints/         # Cross-schema foreign key constraints
```

## Execution Order

Execute the SQL files in the following order:

1. `00-extensions/001-extensions.sql` - Enable required PostgreSQL extensions
2. `01-schemas/001-schemas.sql` - Create database schemas
3. `02-sequences/001-sequences.sql` - Create sequences
4. `03-tables/application/*.sql` - Create Application schema tables (in numeric order)
5. `03-tables/purchasing/*.sql` - Create Purchasing schema tables (in numeric order)
6. `03-tables/sales/*.sql` - Create Sales schema tables (in numeric order)
7. `03-tables/warehouse/*.sql` - Create Warehouse schema tables (in numeric order)
8. `04-temporal-triggers/001-temporal-triggers.sql` - Create temporal trigger functions
9. `06-constraints/001-cross-schema-foreign-keys.sql` - Add cross-schema foreign keys

## Data Type Conversions

| SQL Server Type | PostgreSQL Type |
|-----------------|-----------------|
| `NVARCHAR(n)` | `VARCHAR(n)` |
| `NVARCHAR(MAX)` | `TEXT` |
| `DATETIME2(7)` | `TIMESTAMP` |
| `DATE` | `DATE` |
| `BIT` | `BOOLEAN` |
| `DECIMAL(p,s)` | `NUMERIC(p,s)` |
| `INT` | `INTEGER` |
| `BIGINT` | `BIGINT` |
| `VARBINARY(MAX)` | `BYTEA` |
| `geography` | `GEOGRAPHY` (PostGIS) |
| `IDENTITY` | `GENERATED ALWAYS AS IDENTITY` |
| `NEXT VALUE FOR [Sequences].[X]` | `nextval('sequences.x')` |

## Temporal Tables

SQL Server's system-versioned temporal tables are implemented in PostgreSQL using:

1. **Main table** with `valid_from` and `valid_to` timestamp columns
2. **Archive table** (`_archive` suffix) with composite primary key on `(id, valid_from)`
3. **Trigger function** that archives old versions on UPDATE/DELETE
4. **BEFORE trigger** that executes the trigger function

### Temporal Tables in This Migration

**Application Schema:**
- `people` / `people_archive`
- `countries` / `countries_archive`
- `state_provinces` / `state_provinces_archive`
- `cities` / `cities_archive`
- `delivery_methods` / `delivery_methods_archive`
- `payment_methods` / `payment_methods_archive`
- `transaction_types` / `transaction_types_archive`

**Purchasing Schema:**
- `supplier_categories` / `supplier_categories_archive`
- `suppliers` / `suppliers_archive`

**Sales Schema:**
- `buying_groups` / `buying_groups_archive`
- `customer_categories` / `customer_categories_archive`
- `customers` / `customers_archive`

**Warehouse Schema:**
- `colors` / `colors_archive`
- `package_types` / `package_types_archive`
- `stock_groups` / `stock_groups_archive`
- `stock_items` / `stock_items_archive`
- `cold_room_temperatures` / `cold_room_temperatures_archive`

## Computed Columns

SQL Server computed columns are converted to PostgreSQL `GENERATED ALWAYS AS ... STORED` columns:

- `people.search_name` - Concatenation of preferred_name and full_name
- `people.other_languages` - JSON extraction from custom_fields
- `stock_items.tags` - JSON extraction from custom_fields
- `stock_items.search_details` - Concatenation of stock_item_name and marketing_comments
- `invoices.confirmed_delivery_time` - JSON extraction from returned_delivery_data
- `invoices.confirmed_received_by` - JSON extraction from returned_delivery_data
- `customer_transactions.is_finalized` - Computed from finalization_date
- `supplier_transactions.is_finalized` - Computed from finalization_date

## Memory-Optimized Tables

SQL Server's memory-optimized tables are converted to regular PostgreSQL tables with appropriate indexes:

- `warehouse.cold_room_temperatures` - Uses BIGINT IDENTITY, indexed on sensor_number
- `warehouse.vehicle_temperatures` - Uses BIGINT IDENTITY, indexed on vehicle_registration

## Notes

- **Columnstore indexes**: SQL Server columnstore indexes don't have a direct PostgreSQL equivalent. Consider using BRIN indexes or table partitioning for analytical queries on large tables.
- **Partitioned tables**: SQL Server partitioned tables (CustomerTransactions, SupplierTransactions) are created as regular tables. Consider implementing PostgreSQL native partitioning for production use.
- **Data masking**: SQL Server dynamic data masking is not implemented. Consider using PostgreSQL row-level security or views for sensitive data protection.

## Related Documentation

- [Migration Plan](../migration-docs/migration-plan.md) - Detailed migration strategy
- [SQL Server Feature Inventory](../migration-docs/sql-server-feature-inventory.md) - Complete feature analysis
- [Migration Challenges](../migration-docs/migration-challenges.md) - Known challenges and solutions
