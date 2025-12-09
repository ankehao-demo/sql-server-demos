# Wide World Importers - SQL Server to PostgreSQL Data Type Mapping

This document provides a comprehensive mapping of SQL Server data types to their PostgreSQL equivalents, based on the analysis of the Wide World Importers database schema.

## Executive Summary

The Wide World Importers database uses a variety of SQL Server data types that need to be mapped to PostgreSQL equivalents. This document covers all data types found in the schema, including special considerations for SQL Server-specific features like temporal tables, geography types, and JSON support.

## Data Type Mapping Reference

### Numeric Types

| SQL Server Type | PostgreSQL Type | Notes |
|-----------------|-----------------|-------|
| INT | INTEGER | Direct equivalent |
| BIGINT | BIGINT | Direct equivalent |
| SMALLINT | SMALLINT | Direct equivalent |
| TINYINT | SMALLINT | PostgreSQL has no TINYINT; use SMALLINT |
| BIT | BOOLEAN | Direct equivalent |
| DECIMAL(p,s) | DECIMAL(p,s) / NUMERIC(p,s) | Direct equivalent |
| NUMERIC(p,s) | NUMERIC(p,s) | Direct equivalent |
| MONEY | NUMERIC(19,4) | PostgreSQL has MONEY but NUMERIC is preferred |
| SMALLMONEY | NUMERIC(10,4) | Use NUMERIC |
| FLOAT | DOUBLE PRECISION | Direct equivalent |
| REAL | REAL | Direct equivalent |

### String Types

| SQL Server Type | PostgreSQL Type | Notes |
|-----------------|-----------------|-------|
| CHAR(n) | CHAR(n) | Direct equivalent |
| VARCHAR(n) | VARCHAR(n) | Direct equivalent |
| VARCHAR(MAX) | TEXT | PostgreSQL TEXT has no length limit |
| NCHAR(n) | CHAR(n) | PostgreSQL uses UTF-8 by default |
| NVARCHAR(n) | VARCHAR(n) or TEXT | PostgreSQL uses UTF-8 by default |
| NVARCHAR(MAX) | TEXT | PostgreSQL TEXT has no length limit |
| TEXT | TEXT | Direct equivalent (deprecated in SQL Server) |
| NTEXT | TEXT | Direct equivalent (deprecated in SQL Server) |

### Date and Time Types

| SQL Server Type | PostgreSQL Type | Notes |
|-----------------|-----------------|-------|
| DATE | DATE | Direct equivalent |
| TIME | TIME | Direct equivalent |
| DATETIME | TIMESTAMP | DATETIME has lower precision |
| DATETIME2(n) | TIMESTAMP(n) | Direct equivalent with precision |
| SMALLDATETIME | TIMESTAMP(0) | Lower precision timestamp |
| DATETIMEOFFSET | TIMESTAMPTZ | Timestamp with time zone |

### Binary Types

| SQL Server Type | PostgreSQL Type | Notes |
|-----------------|-----------------|-------|
| BINARY(n) | BYTEA | PostgreSQL uses BYTEA for all binary |
| VARBINARY(n) | BYTEA | PostgreSQL uses BYTEA for all binary |
| VARBINARY(MAX) | BYTEA | PostgreSQL uses BYTEA for all binary |
| IMAGE | BYTEA | Deprecated in SQL Server; use BYTEA |

### Special Types

| SQL Server Type | PostgreSQL Type | Notes |
|-----------------|-----------------|-------|
| UNIQUEIDENTIFIER | UUID | Direct equivalent |
| XML | XML | Direct equivalent |
| GEOGRAPHY | GEOMETRY (PostGIS) | Requires PostGIS extension |
| GEOMETRY | GEOMETRY (PostGIS) | Requires PostGIS extension |
| HIERARCHYID | LTREE or custom | Requires ltree extension or custom implementation |
| SQL_VARIANT | JSONB or custom | No direct equivalent |

### JSON Support

| SQL Server Type | PostgreSQL Type | Notes |
|-----------------|-----------------|-------|
| NVARCHAR(MAX) with JSON | JSONB | PostgreSQL JSONB is more efficient |
| JSON functions | JSONB operators | Different syntax but similar functionality |

## Wide World Importers Specific Mappings

Based on the schema analysis, here are the specific data type mappings required for the Wide World Importers database:

### Application.People Table

| Column | SQL Server Type | PostgreSQL Type | Migration Notes |
|--------|-----------------|-----------------|-----------------|
| PersonID | INT | INTEGER | Use SERIAL or IDENTITY |
| FullName | NVARCHAR(50) | VARCHAR(50) | UTF-8 default |
| PreferredName | NVARCHAR(50) | VARCHAR(50) | UTF-8 default |
| SearchName | AS (computed) | GENERATED ALWAYS AS | Use stored generated column |
| IsPermittedToLogon | BIT | BOOLEAN | Direct mapping |
| LogonName | NVARCHAR(256) | VARCHAR(256) | UTF-8 default |
| IsExternalLogonProvider | BIT | BOOLEAN | Direct mapping |
| HashedPassword | VARBINARY(MAX) | BYTEA | Binary data |
| IsSystemUser | BIT | BOOLEAN | Direct mapping |
| IsEmployee | BIT | BOOLEAN | Direct mapping |
| IsSalesperson | BIT | BOOLEAN | Direct mapping |
| UserPreferences | NVARCHAR(MAX) | JSONB | Store as JSONB for better querying |
| PhoneNumber | NVARCHAR(20) | VARCHAR(20) | UTF-8 default |
| FaxNumber | NVARCHAR(20) | VARCHAR(20) | UTF-8 default |
| EmailAddress | NVARCHAR(256) | VARCHAR(256) | UTF-8 default |
| Photo | VARBINARY(MAX) | BYTEA | Binary data |
| CustomFields | NVARCHAR(MAX) | JSONB | Store as JSONB for better querying |
| OtherLanguages | AS (computed) | GENERATED ALWAYS AS | Extract from JSONB |
| LastEditedBy | INT | INTEGER | Foreign key |
| ValidFrom | DATETIME2(7) | TIMESTAMP(6) | Temporal column |
| ValidTo | DATETIME2(7) | TIMESTAMP(6) | Temporal column |

### Application.Cities Table

| Column | SQL Server Type | PostgreSQL Type | Migration Notes |
|--------|-----------------|-----------------|-----------------|
| CityID | INT | INTEGER | Use SERIAL or IDENTITY |
| CityName | NVARCHAR(50) | VARCHAR(50) | UTF-8 default |
| StateProvinceID | INT | INTEGER | Foreign key |
| Location | geography | GEOMETRY(Point, 4326) | PostGIS with SRID 4326 |
| LatestRecordedPopulation | BIGINT | BIGINT | Direct mapping |
| LastEditedBy | INT | INTEGER | Foreign key |
| ValidFrom | DATETIME2(7) | TIMESTAMP(6) | Temporal column |
| ValidTo | DATETIME2(7) | TIMESTAMP(6) | Temporal column |

### Application.Countries Table

| Column | SQL Server Type | PostgreSQL Type | Migration Notes |
|--------|-----------------|-----------------|-----------------|
| CountryID | INT | INTEGER | Use SERIAL or IDENTITY |
| CountryName | NVARCHAR(60) | VARCHAR(60) | UTF-8 default |
| FormalName | NVARCHAR(60) | VARCHAR(60) | UTF-8 default |
| IsoAlpha3Code | NVARCHAR(3) | CHAR(3) | Fixed length |
| IsoNumericCode | INT | INTEGER | Direct mapping |
| CountryType | NVARCHAR(20) | VARCHAR(20) | UTF-8 default |
| LatestRecordedPopulation | BIGINT | BIGINT | Direct mapping |
| Continent | NVARCHAR(30) | VARCHAR(30) | UTF-8 default |
| Region | NVARCHAR(30) | VARCHAR(30) | UTF-8 default |
| Subregion | NVARCHAR(30) | VARCHAR(30) | UTF-8 default |
| Border | geography | GEOMETRY(MultiPolygon, 4326) | PostGIS with SRID 4326 |
| LastEditedBy | INT | INTEGER | Foreign key |
| ValidFrom | DATETIME2(7) | TIMESTAMP(6) | Temporal column |
| ValidTo | DATETIME2(7) | TIMESTAMP(6) | Temporal column |

### Sales.Customers Table

| Column | SQL Server Type | PostgreSQL Type | Migration Notes |
|--------|-----------------|-----------------|-----------------|
| CustomerID | INT | INTEGER | Use SERIAL or IDENTITY |
| CustomerName | NVARCHAR(100) | VARCHAR(100) | UTF-8 default |
| BillToCustomerID | INT | INTEGER | Self-referential FK |
| CustomerCategoryID | INT | INTEGER | Foreign key |
| BuyingGroupID | INT | INTEGER | Foreign key (nullable) |
| PrimaryContactPersonID | INT | INTEGER | Foreign key |
| AlternateContactPersonID | INT | INTEGER | Foreign key (nullable) |
| DeliveryMethodID | INT | INTEGER | Foreign key |
| DeliveryCityID | INT | INTEGER | Foreign key |
| PostalCityID | INT | INTEGER | Foreign key |
| CreditLimit | DECIMAL(18,2) | NUMERIC(18,2) | Direct mapping |
| AccountOpenedDate | DATE | DATE | Direct mapping |
| StandardDiscountPercentage | DECIMAL(18,3) | NUMERIC(18,3) | Direct mapping |
| IsStatementSent | BIT | BOOLEAN | Direct mapping |
| IsOnCreditHold | BIT | BOOLEAN | Direct mapping |
| PaymentDays | INT | INTEGER | Direct mapping |
| PhoneNumber | NVARCHAR(20) | VARCHAR(20) | UTF-8 default |
| FaxNumber | NVARCHAR(20) | VARCHAR(20) | UTF-8 default |
| DeliveryRun | NVARCHAR(5) | VARCHAR(5) | UTF-8 default |
| RunPosition | NVARCHAR(5) | VARCHAR(5) | UTF-8 default |
| WebsiteURL | NVARCHAR(256) | VARCHAR(256) | UTF-8 default |
| DeliveryAddressLine1 | NVARCHAR(60) | VARCHAR(60) | UTF-8 default |
| DeliveryAddressLine2 | NVARCHAR(60) | VARCHAR(60) | UTF-8 default |
| DeliveryPostalCode | NVARCHAR(10) | VARCHAR(10) | UTF-8 default |
| DeliveryLocation | geography | GEOMETRY(Point, 4326) | PostGIS with SRID 4326 |
| PostalAddressLine1 | NVARCHAR(60) | VARCHAR(60) | UTF-8 default |
| PostalAddressLine2 | NVARCHAR(60) | VARCHAR(60) | UTF-8 default |
| PostalPostalCode | NVARCHAR(10) | VARCHAR(10) | UTF-8 default |
| LastEditedBy | INT | INTEGER | Foreign key |
| ValidFrom | DATETIME2(7) | TIMESTAMP(6) | Temporal column |
| ValidTo | DATETIME2(7) | TIMESTAMP(6) | Temporal column |

### Sales.Orders Table

| Column | SQL Server Type | PostgreSQL Type | Migration Notes |
|--------|-----------------|-----------------|-----------------|
| OrderID | INT | INTEGER | Use SERIAL or IDENTITY |
| CustomerID | INT | INTEGER | Foreign key |
| SalespersonPersonID | INT | INTEGER | Foreign key |
| PickedByPersonID | INT | INTEGER | Foreign key (nullable) |
| ContactPersonID | INT | INTEGER | Foreign key |
| BackorderOrderID | INT | INTEGER | Self-referential FK (nullable) |
| OrderDate | DATE | DATE | Direct mapping |
| ExpectedDeliveryDate | DATE | DATE | Direct mapping |
| CustomerPurchaseOrderNumber | NVARCHAR(20) | VARCHAR(20) | UTF-8 default |
| IsUndersupplyBackordered | BIT | BOOLEAN | Direct mapping |
| Comments | NVARCHAR(MAX) | TEXT | Large text |
| DeliveryInstructions | NVARCHAR(MAX) | TEXT | Large text |
| InternalComments | NVARCHAR(MAX) | TEXT | Large text |
| PickingCompletedWhen | DATETIME2(7) | TIMESTAMP(6) | Direct mapping |
| LastEditedBy | INT | INTEGER | Foreign key |
| LastEditedWhen | DATETIME2(7) | TIMESTAMP(6) | Direct mapping |

### Sales.OrderLines Table

| Column | SQL Server Type | PostgreSQL Type | Migration Notes |
|--------|-----------------|-----------------|-----------------|
| OrderLineID | INT | INTEGER | Use SERIAL or IDENTITY |
| OrderID | INT | INTEGER | Foreign key |
| StockItemID | INT | INTEGER | Foreign key |
| Description | NVARCHAR(100) | VARCHAR(100) | UTF-8 default |
| PackageTypeID | INT | INTEGER | Foreign key |
| Quantity | INT | INTEGER | Direct mapping |
| UnitPrice | DECIMAL(18,2) | NUMERIC(18,2) | Direct mapping |
| TaxRate | DECIMAL(18,3) | NUMERIC(18,3) | Direct mapping |
| PickedQuantity | INT | INTEGER | Direct mapping |
| PickingCompletedWhen | DATETIME2(7) | TIMESTAMP(6) | Direct mapping |
| LastEditedBy | INT | INTEGER | Foreign key |
| LastEditedWhen | DATETIME2(7) | TIMESTAMP(6) | Direct mapping |

### Sales.Invoices Table

| Column | SQL Server Type | PostgreSQL Type | Migration Notes |
|--------|-----------------|-----------------|-----------------|
| InvoiceID | INT | INTEGER | Use SERIAL or IDENTITY |
| CustomerID | INT | INTEGER | Foreign key |
| BillToCustomerID | INT | INTEGER | Foreign key |
| OrderID | INT | INTEGER | Foreign key (nullable) |
| DeliveryMethodID | INT | INTEGER | Foreign key |
| ContactPersonID | INT | INTEGER | Foreign key |
| AccountsPersonID | INT | INTEGER | Foreign key |
| SalespersonPersonID | INT | INTEGER | Foreign key |
| PackedByPersonID | INT | INTEGER | Foreign key |
| InvoiceDate | DATE | DATE | Direct mapping |
| CustomerPurchaseOrderNumber | NVARCHAR(20) | VARCHAR(20) | UTF-8 default |
| IsCreditNote | BIT | BOOLEAN | Direct mapping |
| CreditNoteReason | NVARCHAR(MAX) | TEXT | Large text |
| Comments | NVARCHAR(MAX) | TEXT | Large text |
| DeliveryInstructions | NVARCHAR(MAX) | TEXT | Large text |
| InternalComments | NVARCHAR(MAX) | TEXT | Large text |
| TotalDryItems | INT | INTEGER | Direct mapping |
| TotalChillerItems | INT | INTEGER | Direct mapping |
| DeliveryRun | NVARCHAR(5) | VARCHAR(5) | UTF-8 default |
| RunPosition | NVARCHAR(5) | VARCHAR(5) | UTF-8 default |
| ReturnedDeliveryData | NVARCHAR(MAX) | JSONB | Store as JSONB |
| ConfirmedDeliveryTime | AS (computed) | GENERATED ALWAYS AS | Extract from JSONB |
| ConfirmedReceivedBy | AS (computed) | GENERATED ALWAYS AS | Extract from JSONB |
| LastEditedBy | INT | INTEGER | Foreign key |
| LastEditedWhen | DATETIME2(7) | TIMESTAMP(6) | Direct mapping |

### Purchasing.Suppliers Table

| Column | SQL Server Type | PostgreSQL Type | Migration Notes |
|--------|-----------------|-----------------|-----------------|
| SupplierID | INT | INTEGER | Use SERIAL or IDENTITY |
| SupplierName | NVARCHAR(100) | VARCHAR(100) | UTF-8 default |
| SupplierCategoryID | INT | INTEGER | Foreign key |
| PrimaryContactPersonID | INT | INTEGER | Foreign key |
| AlternateContactPersonID | INT | INTEGER | Foreign key |
| DeliveryMethodID | INT | INTEGER | Foreign key (nullable) |
| DeliveryCityID | INT | INTEGER | Foreign key |
| PostalCityID | INT | INTEGER | Foreign key |
| SupplierReference | NVARCHAR(20) | VARCHAR(20) | UTF-8 default |
| BankAccountName | NVARCHAR(50) MASKED | VARCHAR(50) | Implement masking via views/RLS |
| BankAccountBranch | NVARCHAR(50) MASKED | VARCHAR(50) | Implement masking via views/RLS |
| BankAccountCode | NVARCHAR(20) MASKED | VARCHAR(20) | Implement masking via views/RLS |
| BankAccountNumber | NVARCHAR(20) MASKED | VARCHAR(20) | Implement masking via views/RLS |
| BankInternationalCode | NVARCHAR(20) MASKED | VARCHAR(20) | Implement masking via views/RLS |
| PaymentDays | INT | INTEGER | Direct mapping |
| InternalComments | NVARCHAR(MAX) | TEXT | Large text |
| PhoneNumber | NVARCHAR(20) | VARCHAR(20) | UTF-8 default |
| FaxNumber | NVARCHAR(20) | VARCHAR(20) | UTF-8 default |
| WebsiteURL | NVARCHAR(256) | VARCHAR(256) | UTF-8 default |
| DeliveryAddressLine1 | NVARCHAR(60) | VARCHAR(60) | UTF-8 default |
| DeliveryAddressLine2 | NVARCHAR(60) | VARCHAR(60) | UTF-8 default |
| DeliveryPostalCode | NVARCHAR(10) | VARCHAR(10) | UTF-8 default |
| DeliveryLocation | geography | GEOMETRY(Point, 4326) | PostGIS with SRID 4326 |
| PostalAddressLine1 | NVARCHAR(60) | VARCHAR(60) | UTF-8 default |
| PostalAddressLine2 | NVARCHAR(60) | VARCHAR(60) | UTF-8 default |
| PostalPostalCode | NVARCHAR(10) | VARCHAR(10) | UTF-8 default |
| LastEditedBy | INT | INTEGER | Foreign key |
| ValidFrom | DATETIME2(7) | TIMESTAMP(6) | Temporal column |
| ValidTo | DATETIME2(7) | TIMESTAMP(6) | Temporal column |

### Warehouse.StockItems Table

| Column | SQL Server Type | PostgreSQL Type | Migration Notes |
|--------|-----------------|-----------------|-----------------|
| StockItemID | INT | INTEGER | Use SERIAL or IDENTITY |
| StockItemName | NVARCHAR(100) | VARCHAR(100) | UTF-8 default |
| SupplierID | INT | INTEGER | Foreign key |
| ColorID | INT | INTEGER | Foreign key (nullable) |
| UnitPackageID | INT | INTEGER | Foreign key |
| OuterPackageID | INT | INTEGER | Foreign key |
| Brand | NVARCHAR(50) | VARCHAR(50) | UTF-8 default |
| Size | NVARCHAR(20) | VARCHAR(20) | UTF-8 default |
| LeadTimeDays | INT | INTEGER | Direct mapping |
| QuantityPerOuter | INT | INTEGER | Direct mapping |
| IsChillerStock | BIT | BOOLEAN | Direct mapping |
| Barcode | NVARCHAR(50) | VARCHAR(50) | UTF-8 default |
| TaxRate | DECIMAL(18,3) | NUMERIC(18,3) | Direct mapping |
| UnitPrice | DECIMAL(18,2) | NUMERIC(18,2) | Direct mapping |
| RecommendedRetailPrice | DECIMAL(18,2) | NUMERIC(18,2) | Direct mapping |
| TypicalWeightPerUnit | DECIMAL(18,3) | NUMERIC(18,3) | Direct mapping |
| MarketingComments | NVARCHAR(MAX) | TEXT | Large text |
| InternalComments | NVARCHAR(MAX) | TEXT | Large text |
| Photo | VARBINARY(MAX) | BYTEA | Binary data |
| CustomFields | NVARCHAR(MAX) | JSONB | Store as JSONB |
| Tags | AS (computed) | GENERATED ALWAYS AS | Extract from JSONB |
| SearchDetails | AS (computed) | GENERATED ALWAYS AS | Concatenated search field |
| LastEditedBy | INT | INTEGER | Foreign key |
| ValidFrom | DATETIME2(7) | TIMESTAMP(6) | Temporal column |
| ValidTo | DATETIME2(7) | TIMESTAMP(6) | Temporal column |

### Warehouse.ColdRoomTemperatures Table (Memory-Optimized)

| Column | SQL Server Type | PostgreSQL Type | Migration Notes |
|--------|-----------------|-----------------|-----------------|
| ColdRoomTemperatureID | BIGINT IDENTITY | BIGSERIAL | Auto-increment |
| ColdRoomSensorNumber | INT | INTEGER | Direct mapping |
| RecordedWhen | DATETIME2(7) | TIMESTAMP(6) | Direct mapping |
| Temperature | DECIMAL(10,2) | NUMERIC(10,2) | Direct mapping |
| ValidFrom | DATETIME2(7) | TIMESTAMP(6) | Temporal column |
| ValidTo | DATETIME2(7) | TIMESTAMP(6) | Temporal column |

## Special Feature Mappings

### 1. Temporal Tables

SQL Server temporal tables use SYSTEM_VERSIONING with automatic history tracking. PostgreSQL does not have native temporal tables, but can implement similar functionality using:

**Option A: Triggers (Recommended)**
```sql
-- Create history table
CREATE TABLE application.people_history (LIKE application.people);

-- Create trigger function
CREATE OR REPLACE FUNCTION application.people_history_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE' OR TG_OP = 'DELETE' THEN
        INSERT INTO application.people_history SELECT OLD.*;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
CREATE TRIGGER people_history
BEFORE UPDATE OR DELETE ON application.people
FOR EACH ROW EXECUTE FUNCTION application.people_history_trigger();
```

**Option B: temporal_tables Extension**
```sql
-- Install extension
CREATE EXTENSION temporal_tables;

-- Enable versioning
SELECT enable_versioning('application.people', 'application.people_history');
```

### 2. Geography/Spatial Data

SQL Server geography type maps to PostGIS geometry type with SRID 4326 (WGS 84):

```sql
-- Enable PostGIS
CREATE EXTENSION postgis;

-- Create column
ALTER TABLE application.cities 
ADD COLUMN location GEOMETRY(Point, 4326);

-- Create spatial index
CREATE INDEX idx_cities_location ON application.cities USING GIST (location);
```

### 3. JSON Support

SQL Server JSON functions map to PostgreSQL JSONB operators:

| SQL Server | PostgreSQL | Description |
|------------|------------|-------------|
| JSON_VALUE(col, '$.path') | col->>'path' | Extract text value |
| JSON_QUERY(col, '$.path') | col->'path' | Extract JSON object |
| ISJSON(col) | col IS JSON | Validate JSON |
| JSON_MODIFY(col, '$.path', val) | jsonb_set(col, '{path}', val) | Modify JSON |
| OPENJSON(col) | jsonb_each(col) | Expand JSON |
| FOR JSON PATH | row_to_json() / json_agg() | Generate JSON |

### 4. Full-Text Search

SQL Server full-text search maps to PostgreSQL tsvector/tsquery:

| SQL Server | PostgreSQL | Description |
|------------|------------|-------------|
| CREATE FULLTEXT INDEX | CREATE INDEX ... USING GIN (to_tsvector(...)) | Create FTS index |
| CONTAINS(col, 'term') | to_tsvector(col) @@ to_tsquery('term') | Search |
| FREETEXT(col, 'term') | to_tsvector(col) @@ plainto_tsquery('term') | Natural language search |
| FREETEXTTABLE | ts_rank() with subquery | Ranked search |

### 5. Dynamic Data Masking

PostgreSQL does not have native Dynamic Data Masking. Implement using views or Row-Level Security:

**Option A: Views with Masking Functions**
```sql
CREATE OR REPLACE FUNCTION mask_bank_account(val TEXT)
RETURNS TEXT AS $$
BEGIN
    IF current_user = 'admin' THEN
        RETURN val;
    ELSE
        RETURN 'XXXX' || RIGHT(val, 4);
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE VIEW purchasing.suppliers_masked AS
SELECT 
    supplier_id,
    supplier_name,
    mask_bank_account(bank_account_number) AS bank_account_number
FROM purchasing.suppliers;
```

**Option B: Row-Level Security with Column Masking**
```sql
CREATE POLICY supplier_bank_policy ON purchasing.suppliers
FOR SELECT
USING (
    current_user = 'admin' 
    OR bank_account_number IS NULL
);
```

### 6. Row-Level Security

PostgreSQL has native RLS support similar to SQL Server:

```sql
-- Enable RLS
ALTER TABLE sales.customers ENABLE ROW LEVEL SECURITY;

-- Create policy
CREATE POLICY customer_territory_policy ON sales.customers
FOR ALL
USING (
    current_user = 'admin'
    OR EXISTS (
        SELECT 1 FROM application.cities c
        JOIN application.state_provinces sp ON c.state_province_id = sp.state_province_id
        WHERE c.city_id = delivery_city_id
        AND sp.sales_territory = current_setting('app.sales_territory', true)
    )
);
```

### 7. Sequences

SQL Server sequences map directly to PostgreSQL sequences:

```sql
-- SQL Server
CREATE SEQUENCE [Sequences].[PersonID] AS INT START WITH 1;

-- PostgreSQL
CREATE SEQUENCE sequences.person_id START WITH 1;
```

### 8. Computed Columns

SQL Server computed columns map to PostgreSQL generated columns:

```sql
-- SQL Server
[SearchName] AS (concat([PreferredName], N' ', [FullName])) PERSISTED

-- PostgreSQL
search_name VARCHAR(101) GENERATED ALWAYS AS (preferred_name || ' ' || full_name) STORED
```

### 9. Columnstore Indexes

PostgreSQL does not have columnstore indexes. Alternatives include:

1. **BRIN Indexes**: For large tables with naturally ordered data
2. **Table Partitioning**: For improved query performance on large tables
3. **Materialized Views**: For pre-aggregated analytics
4. **TimescaleDB Extension**: For time-series data with compression

### 10. Memory-Optimized Tables

PostgreSQL does not have memory-optimized tables. The standard PostgreSQL tables with proper indexing and configuration should provide adequate performance. Consider:

1. **Unlogged Tables**: For temporary data that doesn't need durability
2. **Proper shared_buffers Configuration**: To maximize memory usage
3. **Connection Pooling**: Using PgBouncer for high-concurrency scenarios

## Collation Considerations

SQL Server uses various collations (e.g., Latin1_General_100_CI_AS). PostgreSQL uses ICU collations:

```sql
-- Create database with specific collation
CREATE DATABASE wideworldimporters 
WITH ENCODING = 'UTF8' 
LC_COLLATE = 'en_US.UTF-8' 
LC_CTYPE = 'en_US.UTF-8';

-- Or use ICU collation for specific columns
CREATE COLLATION en_ci (provider = icu, locale = 'en-US-u-ks-level2', deterministic = false);
ALTER TABLE application.people ALTER COLUMN full_name TYPE VARCHAR(50) COLLATE en_ci;
```

## Default Value Mappings

| SQL Server | PostgreSQL | Notes |
|------------|------------|-------|
| GETDATE() | CURRENT_TIMESTAMP | Current timestamp |
| SYSDATETIME() | CURRENT_TIMESTAMP | Current timestamp with precision |
| NEWID() | gen_random_uuid() | UUID generation |
| NEXT VALUE FOR seq | nextval('seq') | Sequence next value |
| DEFAULT (0) | DEFAULT 0 | Numeric default |
| DEFAULT ('') | DEFAULT '' | String default |

## Constraint Mappings

| SQL Server | PostgreSQL | Notes |
|------------|------------|-------|
| PRIMARY KEY | PRIMARY KEY | Direct equivalent |
| FOREIGN KEY | FOREIGN KEY | Direct equivalent |
| UNIQUE | UNIQUE | Direct equivalent |
| CHECK | CHECK | Direct equivalent |
| DEFAULT | DEFAULT | Direct equivalent |
| NOT NULL | NOT NULL | Direct equivalent |

## Index Type Mappings

| SQL Server Index | PostgreSQL Index | Notes |
|------------------|------------------|-------|
| CLUSTERED | Primary key index | PostgreSQL tables are heap-organized |
| NONCLUSTERED | B-tree index | Default index type |
| COLUMNSTORE | BRIN or partitioning | No direct equivalent |
| SPATIAL | GiST | For PostGIS geometry |
| FULLTEXT | GIN with tsvector | For full-text search |
| FILTERED | Partial index | WHERE clause on index |
| INCLUDE | INCLUDE | Covering index columns |

## Summary of Key Mappings

| Category | SQL Server | PostgreSQL |
|----------|------------|------------|
| Unicode strings | NVARCHAR | VARCHAR (UTF-8 default) |
| Large text | NVARCHAR(MAX) | TEXT |
| Binary data | VARBINARY(MAX) | BYTEA |
| Timestamps | DATETIME2 | TIMESTAMP |
| Boolean | BIT | BOOLEAN |
| Spatial | geography | GEOMETRY (PostGIS) |
| JSON | NVARCHAR with JSON functions | JSONB |
| Auto-increment | IDENTITY or SEQUENCE | SERIAL or IDENTITY |
| Temporal tables | SYSTEM_VERSIONING | Triggers or temporal_tables extension |
| Full-text search | FULLTEXT INDEX | GIN index with tsvector |
| Row-Level Security | SECURITY POLICY | ROW LEVEL SECURITY |
| Dynamic Data Masking | MASKED WITH | Views or RLS |
| Memory-optimized | MEMORY_OPTIMIZED | Standard tables |
| Columnstore | COLUMNSTORE INDEX | BRIN or partitioning |
