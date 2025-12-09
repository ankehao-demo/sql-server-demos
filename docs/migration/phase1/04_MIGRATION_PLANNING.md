# Wide World Importers - PostgreSQL Migration Planning Document

This document summarizes the Phase 1 analysis, mappings, and design decisions for migrating the Wide World Importers database from SQL Server to PostgreSQL.

## Executive Summary

The Wide World Importers database migration from SQL Server to PostgreSQL is a comprehensive project that requires careful planning due to the extensive use of SQL Server-specific features. This document consolidates findings from the schema analysis, data type mapping, and PostgreSQL ERD design phases to provide a clear roadmap for the migration.

### Key Statistics

| Metric | Count |
|--------|-------|
| Total Tables | 33 |
| Temporal Tables | 17 |
| Tables with Geography Data | 6 |
| Tables with JSON Data | 5 |
| Tables with Full-Text Search | 4 |
| Stored Procedures | 60+ |
| Views | 25+ |
| Sequences | 26 |

### Migration Complexity Assessment

| Feature | SQL Server | PostgreSQL Equivalent | Complexity |
|---------|------------|----------------------|------------|
| Temporal Tables | Native SYSTEM_VERSIONING | Triggers + History Tables | High |
| Geography Data | Native geography type | PostGIS extension | Medium |
| JSON Support | JSON functions | JSONB (superior) | Low |
| Full-Text Search | FULLTEXT INDEX | tsvector/tsquery | Medium |
| Row-Level Security | SECURITY POLICY | Native RLS | Low |
| Dynamic Data Masking | MASKED WITH | Views + Functions | Medium |
| Memory-Optimized Tables | MEMORY_OPTIMIZED | Standard Tables | Low |
| Columnstore Indexes | COLUMNSTORE INDEX | BRIN + Partitioning | Medium |
| Sequences | Native sequences | Native sequences | Low |

## Migration Strategy

### Phase Overview

The migration will be executed in multiple phases:

| Phase | Description | Duration | Status |
|-------|-------------|----------|--------|
| Phase 1 | Planning & ERD Design | 2-3 weeks | Current |
| Phase 2 | Schema Migration | 2-3 weeks | Planned |
| Phase 3 | Data Migration | 2-4 weeks | Planned |
| Phase 4 | Application Migration | 3-4 weeks | Planned |
| Phase 5 | Testing & Validation | 2-3 weeks | Planned |
| Phase 6 | Cutover & Go-Live | 1 week | Planned |

### Migration Approach

We recommend a **parallel migration** approach:

1. Create PostgreSQL schema alongside existing SQL Server
2. Set up continuous data synchronization
3. Migrate application components incrementally
4. Validate data integrity at each step
5. Perform final cutover with minimal downtime

## Schema Migration Plan

### Schema Creation Order

Due to foreign key dependencies, schemas must be created in this order:

1. **sequences** - ID generation sequences
2. **application** - Core reference data (no external dependencies)
3. **purchasing** - Supplier data (depends on application)
4. **warehouse** - Stock items (depends on application, purchasing)
5. **sales** - Customer and order data (depends on application, warehouse)
6. **webapi** - API views (depends on all other schemas)
7. **website** - Web application support (depends on all other schemas)

### Table Creation Order

Within each schema, tables must be created respecting foreign key dependencies:

#### Application Schema
1. people (self-referential, create without FK first)
2. countries
3. state_provinces
4. cities
5. delivery_methods
6. payment_methods
7. transaction_types
8. system_parameters
9. Add FK constraint to people.last_edited_by

#### Sales Schema
1. customer_categories
2. buying_groups
3. customers
4. orders
5. order_lines
6. invoices
7. invoice_lines
8. customer_transactions
9. special_deals

#### Purchasing Schema
1. supplier_categories
2. suppliers
3. purchase_orders
4. purchase_order_lines
5. supplier_transactions

#### Warehouse Schema
1. colors
2. package_types
3. stock_groups
4. stock_items
5. stock_item_stock_groups
6. stock_item_holdings
7. stock_item_transactions
8. cold_room_temperatures
9. vehicle_temperatures

## Feature Migration Details

### 1. Temporal Tables Migration

**Current State:** 17 tables use SQL Server's SYSTEM_VERSIONING with automatic history tracking.

**Migration Strategy:**
1. Create main tables with valid_from and valid_to columns
2. Create corresponding _history tables
3. Implement trigger-based history tracking
4. Migrate historical data from SQL Server archive tables

**Implementation:**
```sql
-- Create history trigger function (reusable)
CREATE OR REPLACE FUNCTION track_history()
RETURNS TRIGGER AS $$
DECLARE
    history_table TEXT;
BEGIN
    history_table := TG_TABLE_SCHEMA || '.' || TG_TABLE_NAME || '_history';
    
    IF TG_OP = 'UPDATE' THEN
        OLD.valid_to = CURRENT_TIMESTAMP;
        EXECUTE format('INSERT INTO %I SELECT $1.*', history_table) USING OLD;
        NEW.valid_from = CURRENT_TIMESTAMP;
        NEW.valid_to = '9999-12-31 23:59:59.999999';
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        OLD.valid_to = CURRENT_TIMESTAMP;
        EXECUTE format('INSERT INTO %I SELECT $1.*', history_table) USING OLD;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;
```

**Tables Requiring Temporal Migration:**
- application.people
- application.countries
- application.state_provinces
- application.cities
- application.delivery_methods
- application.payment_methods
- application.transaction_types
- sales.customers
- sales.customer_categories
- sales.buying_groups
- purchasing.suppliers
- purchasing.supplier_categories
- warehouse.stock_items
- warehouse.stock_groups
- warehouse.colors
- warehouse.package_types
- warehouse.cold_room_temperatures

### 2. Spatial Data Migration

**Current State:** 6 tables use SQL Server's geography type for spatial data.

**Migration Strategy:**
1. Enable PostGIS extension
2. Create geometry columns with SRID 4326 (WGS 84)
3. Convert SQL Server geography to PostGIS geometry during data migration
4. Create spatial indexes using GiST

**Data Conversion:**
```sql
-- SQL Server geography to PostGIS geometry
-- Point: geography::Point(lat, long, 4326) -> ST_SetSRID(ST_MakePoint(long, lat), 4326)
-- Polygon: geography::STGeomFromText(wkt, 4326) -> ST_GeomFromText(wkt, 4326)
```

**Tables Requiring Spatial Migration:**
- application.countries (border - MultiPolygon)
- application.state_provinces (border - MultiPolygon)
- application.cities (location - Point)
- application.system_parameters (delivery_location - Point)
- sales.customers (delivery_location - Point)
- purchasing.suppliers (delivery_location - Point)

### 3. JSON Data Migration

**Current State:** 5 tables store JSON data in NVARCHAR(MAX) columns with JSON functions.

**Migration Strategy:**
1. Convert NVARCHAR(MAX) JSON columns to JSONB
2. Update computed columns to use PostgreSQL JSONB operators
3. Create GIN indexes for JSONB columns
4. Validate JSON data during migration

**JSON Column Mappings:**
| Table | Column | SQL Server | PostgreSQL |
|-------|--------|------------|------------|
| application.people | user_preferences | NVARCHAR(MAX) | JSONB |
| application.people | custom_fields | NVARCHAR(MAX) | JSONB |
| application.system_parameters | application_settings | NVARCHAR(MAX) | JSONB |
| warehouse.stock_items | custom_fields | NVARCHAR(MAX) | JSONB |
| sales.invoices | returned_delivery_data | NVARCHAR(MAX) | JSONB |
| warehouse.vehicle_temperatures | full_sensor_data | NVARCHAR(1000) | JSONB |

### 4. Full-Text Search Migration

**Current State:** 4 tables have full-text indexes for search functionality.

**Migration Strategy:**
1. Add tsvector columns to searchable tables
2. Create GIN indexes on tsvector columns
3. Implement search functions using ts_rank
4. Update stored procedures to use PostgreSQL full-text syntax

**Full-Text Search Tables:**
| Table | Searchable Columns | Index Type |
|-------|-------------------|------------|
| application.people | full_name, preferred_name, custom_fields | GIN(tsvector) |
| sales.customers | customer_name | GIN(tsvector) |
| purchasing.suppliers | supplier_name | GIN(tsvector) |
| warehouse.stock_items | stock_item_name, marketing_comments, tags | GIN(tsvector) |

### 5. Row-Level Security Migration

**Current State:** Sales.Customers table has RLS policy based on sales territory.

**Migration Strategy:**
1. Enable RLS on sales.customers table
2. Create policy using current_setting() for session context
3. Implement session context setting in application layer
4. Test access control for different territories

**RLS Implementation:**
```sql
-- Enable RLS
ALTER TABLE sales.customers ENABLE ROW LEVEL SECURITY;

-- Create policy
CREATE POLICY customer_territory_policy ON sales.customers
FOR ALL
USING (
    current_setting('app.is_admin', true)::boolean = true
    OR current_setting('app.sales_territory', true) = 'ALL_TERRITORIES'
    OR EXISTS (
        SELECT 1 FROM application.cities c
        JOIN application.state_provinces sp ON c.state_province_id = sp.state_province_id
        WHERE c.city_id = delivery_city_id
        AND sp.sales_territory = current_setting('app.sales_territory', true)
    )
);

-- Application must set context before queries
SET app.sales_territory = 'Far West';
```

### 6. Dynamic Data Masking Migration

**Current State:** Purchasing.Suppliers has masked bank account columns.

**Migration Strategy:**
1. Create masking functions
2. Create masked views for application access
3. Implement role-based access to underlying tables
4. Update application to use masked views

**Masked Columns:**
- bank_account_name
- bank_account_branch
- bank_account_code
- bank_account_number
- bank_international_code

### 7. Memory-Optimized Table Migration

**Current State:** Warehouse.ColdRoomTemperatures uses MEMORY_OPTIMIZED.

**Migration Strategy:**
1. Create standard PostgreSQL table with partitioning
2. Use UNLOGGED tables if durability is not required
3. Optimize shared_buffers for memory performance
4. Consider TimescaleDB for time-series optimization

### 8. Columnstore Index Migration

**Current State:** Sales.OrderLines and Sales.InvoiceLines have columnstore indexes.

**Migration Strategy:**
1. Create BRIN indexes for range queries on large tables
2. Implement table partitioning for improved query performance
3. Consider materialized views for pre-aggregated analytics
4. Evaluate columnar storage extensions if needed

## Data Migration Plan

### Migration Tools

| Tool | Purpose | Use Case |
|------|---------|----------|
| pgloader | Bulk data migration | Initial data load |
| pg_dump/pg_restore | Backup and restore | Schema migration |
| Custom Python scripts | Data transformation | Complex transformations |
| Debezium | Change data capture | Continuous sync |

### Data Migration Steps

1. **Schema Export**
   - Export SQL Server schema definitions
   - Convert to PostgreSQL DDL
   - Apply PostgreSQL-specific optimizations

2. **Initial Data Load**
   - Disable foreign keys and triggers
   - Load reference data (application schema)
   - Load transactional data (sales, purchasing, warehouse)
   - Re-enable foreign keys and triggers
   - Validate row counts and checksums

3. **Incremental Sync**
   - Set up change data capture on SQL Server
   - Stream changes to PostgreSQL
   - Maintain data consistency during migration period

4. **Data Validation**
   - Compare row counts between databases
   - Validate data integrity with checksums
   - Test business logic with sample queries
   - Verify spatial data accuracy

### Data Transformation Requirements

| Source Type | Target Type | Transformation |
|-------------|-------------|----------------|
| geography Point | geometry(Point, 4326) | Swap lat/long coordinates |
| geography Polygon | geometry(MultiPolygon, 4326) | Convert WKT format |
| NVARCHAR JSON | JSONB | Parse and validate JSON |
| DATETIME2 | TIMESTAMP | Direct conversion |
| BIT | BOOLEAN | 1->true, 0->false |
| VARBINARY | BYTEA | Hex encoding |

## Application Migration Plan

### Database Connection Changes

**Current (SQL Server):**
```csharp
// .NET connection string
"Server=localhost;Database=WideWorldImporters;User Id=sa;Password=xxx;"
```

**Target (PostgreSQL):**
```csharp
// Npgsql connection string
"Host=localhost;Database=wideworldimporters;Username=webapi;Password=xxx;"
```

### Query Syntax Changes

| SQL Server | PostgreSQL | Notes |
|------------|------------|-------|
| TOP n | LIMIT n | Position in query |
| GETDATE() | CURRENT_TIMESTAMP | Current timestamp |
| ISNULL(a, b) | COALESCE(a, b) | Null handling |
| CONVERT(type, val) | val::type | Type casting |
| + (string concat) | \|\| | String concatenation |
| [column] | "column" | Identifier quoting |
| #temp | temp table | Temporary tables |
| @variable | variable | Variable syntax |

### Stored Procedure Migration

Stored procedures will need to be converted to PostgreSQL functions:

**SQL Server:**
```sql
CREATE PROCEDURE [Website].[SearchForCustomers]
    @SearchText NVARCHAR(1000)
AS
BEGIN
    SELECT CustomerID, CustomerName
    FROM Sales.Customers
    WHERE CONTAINS(CustomerName, @SearchText)
END
```

**PostgreSQL:**
```sql
CREATE OR REPLACE FUNCTION website.search_for_customers(search_text TEXT)
RETURNS TABLE(customer_id INTEGER, customer_name VARCHAR(100))
AS $$
BEGIN
    RETURN QUERY
    SELECT c.customer_id, c.customer_name
    FROM sales.customers c
    WHERE c.search_vector @@ plainto_tsquery('english', search_text);
END;
$$ LANGUAGE plpgsql;
```

### WebApi Changes

The WebApi views need to be recreated in PostgreSQL with syntax adjustments:

1. Replace JSON_QUERY with JSONB operators
2. Replace geography methods with PostGIS functions
3. Update FOR JSON PATH to json_agg/row_to_json
4. Adjust column aliases and quoting

## ETL Process Migration

### Current SSIS Process

The existing ETL uses SSIS to migrate data from WideWorldImporters (OLTP) to WideWorldImportersDW (OLAP).

### PostgreSQL ETL Options

| Option | Description | Recommendation |
|--------|-------------|----------------|
| Apache Airflow | Workflow orchestration | Recommended for complex ETL |
| pg_cron | PostgreSQL job scheduler | Simple scheduled jobs |
| dbt | Data transformation | Analytics transformations |
| Custom Python | Flexible scripting | Complex transformations |

### ETL Migration Strategy

1. Document existing SSIS packages
2. Identify transformation logic
3. Implement equivalent PostgreSQL functions
4. Create scheduling mechanism (pg_cron or Airflow)
5. Validate ETL output against original

## Testing Plan

### Unit Testing

| Test Category | Description | Tools |
|---------------|-------------|-------|
| Schema Validation | Verify table structures | pgTAP |
| Data Type Validation | Verify data type mappings | Custom scripts |
| Constraint Testing | Verify FK/PK constraints | pgTAP |
| Index Testing | Verify index creation | EXPLAIN ANALYZE |

### Integration Testing

| Test Category | Description | Approach |
|---------------|-------------|----------|
| Full-Text Search | Verify search functionality | Compare results |
| Spatial Queries | Verify PostGIS operations | Compare distances |
| RLS Testing | Verify access control | Multi-user testing |
| JSON Operations | Verify JSONB queries | Compare outputs |

### Performance Testing

| Test Category | Baseline | Target |
|---------------|----------|--------|
| Simple SELECT | < 10ms | < 10ms |
| Complex JOIN | < 100ms | < 100ms |
| Full-Text Search | < 50ms | < 50ms |
| Spatial Query | < 100ms | < 100ms |
| Bulk INSERT | 10K rows/sec | 10K rows/sec |

### Data Validation

| Validation | Method | Frequency |
|------------|--------|-----------|
| Row Counts | COUNT(*) comparison | After each load |
| Checksums | MD5 hash comparison | After each load |
| Sample Queries | Business logic validation | Daily |
| Referential Integrity | FK constraint check | After migration |

## Risk Assessment

### High Risk Items

| Risk | Impact | Mitigation |
|------|--------|------------|
| Temporal table data loss | Data integrity | Thorough testing, backup strategy |
| Spatial data accuracy | Business operations | Coordinate validation, visual verification |
| RLS policy gaps | Security breach | Comprehensive access testing |
| Performance degradation | User experience | Performance benchmarking, optimization |

### Medium Risk Items

| Risk | Impact | Mitigation |
|------|--------|------------|
| JSON data corruption | Data integrity | JSON validation during migration |
| Full-text search differences | Search quality | Search result comparison |
| Stored procedure bugs | Application errors | Unit testing, code review |
| ETL timing issues | Data freshness | Monitoring, alerting |

### Low Risk Items

| Risk | Impact | Mitigation |
|------|--------|------------|
| Sequence gaps | Cosmetic | Document expected behavior |
| Collation differences | Sort order | Explicit collation settings |
| Timestamp precision | Minor | Use TIMESTAMP(6) |

## Resource Requirements

### Team Composition

| Role | Responsibility | FTE |
|------|----------------|-----|
| Database Architect | Schema design, optimization | 0.5 |
| Database Developer | Migration scripts, stored procedures | 1.0 |
| Application Developer | Application code changes | 1.0 |
| QA Engineer | Testing, validation | 0.5 |
| DevOps Engineer | Infrastructure, deployment | 0.25 |

### Infrastructure Requirements

| Component | Specification | Purpose |
|-----------|---------------|---------|
| PostgreSQL Server | 4 CPU, 16GB RAM, 500GB SSD | Production database |
| Migration Server | 2 CPU, 8GB RAM | ETL processing |
| Test Environment | Mirror of production | Testing |

### Timeline Estimate

| Phase | Duration | Dependencies |
|-------|----------|--------------|
| Phase 1: Planning | 2-3 weeks | None |
| Phase 2: Schema Migration | 2-3 weeks | Phase 1 |
| Phase 3: Data Migration | 2-4 weeks | Phase 2 |
| Phase 4: Application Migration | 3-4 weeks | Phase 3 |
| Phase 5: Testing | 2-3 weeks | Phase 4 |
| Phase 6: Cutover | 1 week | Phase 5 |
| **Total** | **12-18 weeks** | |

## Success Criteria

### Phase 1 Completion Criteria (Current Phase)

- [x] Complete schema analysis document
- [x] Complete data type mapping document
- [x] Complete PostgreSQL ERD design
- [x] Complete migration planning document
- [ ] Stakeholder review and approval

### Overall Migration Success Criteria

- All data migrated with 100% accuracy
- Application functionality preserved
- Performance meets or exceeds baseline
- Security controls maintained
- Zero data loss during cutover
- Rollback capability verified

## Next Steps

### Immediate Actions (Phase 2 Preparation)

1. Review and approve Phase 1 deliverables
2. Set up PostgreSQL development environment
3. Begin schema creation scripts
4. Identify pilot tables for initial migration testing
5. Establish data validation framework

### Phase 2 Deliverables

1. PostgreSQL schema creation scripts
2. Temporal table trigger implementations
3. PostGIS spatial data setup
4. Full-text search configuration
5. Row-Level Security policies
6. Data masking views

## Appendices

### Appendix A: Reference Documents

1. [01_CURRENT_SCHEMA_ANALYSIS.md](./01_CURRENT_SCHEMA_ANALYSIS.md) - Detailed SQL Server schema analysis
2. [02_DATA_TYPE_MAPPING.md](./02_DATA_TYPE_MAPPING.md) - Complete data type mapping reference
3. [03_POSTGRESQL_ERD.md](./03_POSTGRESQL_ERD.md) - PostgreSQL entity relationship diagram
4. [POSTGRESQL_MIGRATION_GUIDE.md](../../../POSTGRESQL_MIGRATION_GUIDE.md) - General migration guidance

### Appendix B: SQL Server Feature Reference

| Feature | SQL Server Version | PostgreSQL Equivalent |
|---------|-------------------|----------------------|
| Temporal Tables | 2016+ | Triggers + History Tables |
| JSON Support | 2016+ | JSONB (native) |
| Row-Level Security | 2016+ | Native RLS |
| Dynamic Data Masking | 2016+ | Views + Functions |
| Memory-Optimized Tables | 2014+ | Standard Tables |
| Columnstore Indexes | 2012+ | BRIN + Partitioning |
| Full-Text Search | 2005+ | tsvector/tsquery |
| Geography Type | 2008+ | PostGIS |

### Appendix C: PostgreSQL Extensions Required

| Extension | Purpose | Installation |
|-----------|---------|--------------|
| PostGIS | Spatial data support | CREATE EXTENSION postgis; |
| pg_trgm | Fuzzy text matching | CREATE EXTENSION pg_trgm; |
| btree_gin | GIN index support | CREATE EXTENSION btree_gin; |
| pg_partman | Partition management | CREATE EXTENSION pg_partman; |

### Appendix D: Contact Information

| Role | Contact | Responsibility |
|------|---------|----------------|
| Project Lead | TBD | Overall coordination |
| Technical Lead | TBD | Technical decisions |
| DBA | TBD | Database operations |
| QA Lead | TBD | Testing coordination |
