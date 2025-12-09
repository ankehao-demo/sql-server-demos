# Migration Challenges - Wide World Importers SQL Server to PostgreSQL

This document highlights specific challenges found in the Wide World Importers codebase that require special attention during PostgreSQL migration.

## 1. Temporal Tables (System-Versioned Tables)

### Challenge Description

SQL Server's temporal tables provide automatic tracking of data changes with system-versioned history. PostgreSQL does not have native temporal table support.

### Tables Affected

**OLTP Database (17 temporal tables):**

| Schema | Table | History Table |
|--------|-------|---------------|
| Application | Cities | Cities_Archive |
| Application | Countries | Countries_Archive |
| Application | DeliveryMethods | DeliveryMethods_Archive |
| Application | PaymentMethods | PaymentMethods_Archive |
| Application | People | People_Archive |
| Application | StateProvinces | StateProvinces_Archive |
| Application | TransactionTypes | TransactionTypes_Archive |
| Sales | BuyingGroups | BuyingGroups_Archive |
| Sales | CustomerCategories | CustomerCategories_Archive |
| Sales | Customers | Customers_Archive |
| Warehouse | ColdRoomTemperatures | ColdRoomTemperatures_Archive |
| Warehouse | Colors | Colors_Archive |
| Warehouse | PackageTypes | PackageTypes_Archive |
| Warehouse | StockGroups | StockGroups_Archive |
| Warehouse | StockItems | StockItems_Archive |
| Purchasing | SupplierCategories | SupplierCategories_Archive |
| Purchasing | Suppliers | Suppliers_Archive |

### SQL Server Features Used

```sql
-- Column definitions
[ValidFrom] DATETIME2 (7) GENERATED ALWAYS AS ROW START NOT NULL,
[ValidTo]   DATETIME2 (7) GENERATED ALWAYS AS ROW END   NOT NULL,
PERIOD FOR SYSTEM_TIME ([ValidFrom], [ValidTo])

-- Table option
WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE=[Schema].[Table_Archive], DATA_CONSISTENCY_CHECK=ON))

-- Temporal queries
SELECT * FROM Application.Cities FOR SYSTEM_TIME AS OF '2020-01-01'
SELECT * FROM Application.Cities FOR SYSTEM_TIME BETWEEN '2020-01-01' AND '2020-12-31'
```

### Migration Approach Required

1. Create main table with `valid_from` and `valid_to` columns
2. Create corresponding `_archive` history table
3. Implement triggers for INSERT, UPDATE, DELETE to maintain history
4. Create views or functions to simulate `FOR SYSTEM_TIME` queries

### Complexity: HIGH

The Integration schema procedures heavily rely on temporal queries for ETL operations:
- `Integration.GetCityUpdates`
- `Integration.GetCustomerUpdates`
- `Integration.GetEmployeeUpdates`
- All 13 Integration procedures use `FOR SYSTEM_TIME` clauses

---

## 2. Memory-Optimized Tables (In-Memory OLTP)

### Challenge Description

SQL Server's In-Memory OLTP provides memory-optimized tables and natively compiled procedures for high-performance scenarios. PostgreSQL does not have an equivalent feature.

### Tables Affected

| Schema | Table | Features |
|--------|-------|----------|
| Warehouse | ColdRoomTemperatures | Memory-optimized + Temporal |
| Warehouse | VehicleTemperatures | Memory-optimized only |

### Memory-Optimized Table-Valued Types

| Schema | Type | Purpose |
|--------|------|---------|
| Website | OrderIDList | Batch order processing |
| Website | OrderList | Order header collection |
| Website | OrderLineList | Order line collection |
| Website | SensorDataList | Sensor data batch insert |

### Natively Compiled Procedures

```sql
-- Website.RecordColdRoomTemperatures
CREATE PROCEDURE [Website].[RecordColdRoomTemperatures]
@SensorReadings Website.SensorDataList READONLY
WITH NATIVE_COMPILATION, SCHEMABINDING, EXECUTE AS OWNER
AS
BEGIN ATOMIC WITH
(
    TRANSACTION ISOLATION LEVEL = SNAPSHOT,
    LANGUAGE = N'English'
)
    -- Procedure body
END;
```

### Migration Approach Required

1. Convert memory-optimized tables to regular PostgreSQL tables
2. Replace memory-optimized TVPs with regular table types or temporary tables
3. Convert natively compiled procedures to standard PL/pgSQL functions
4. Consider using `UNLOGGED` tables for high-write scenarios (no WAL logging)
5. Implement connection pooling and prepared statements for performance

### Complexity: MEDIUM-HIGH

Performance testing will be critical to ensure acceptable throughput for temperature recording operations.

---

## 3. DataLoadSimulation Procedures

### Challenge Description

The `DataLoadSimulation` schema contains 41 stored procedures that simulate business operations and generate historical data. These procedures use many SQL Server-specific features.

### Key Procedure: `PopulateDataToCurrentDate`

```sql
CREATE PROCEDURE DataLoadSimulation.PopulateDataToCurrentDate
@AverageNumberOfCustomerOrdersPerDay int,
@SaturdayPercentageOfNormalWorkDay int,
@SundayPercentageOfNormalWorkDay int,
@IsSilentMode bit,
@AreDatesPrinted bit
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @CurrentMaximumDate date = COALESCE((SELECT MAX(OrderDate) FROM Sales.Orders), '20191231');
    DECLARE @StartingDate date = DATEADD(day, 1, @CurrentMaximumDate);
    DECLARE @EndingDate date = CAST(DATEADD(day, -1, SYSDATETIME()) AS date);
    
    EXEC DataLoadSimulation.DailyProcessToCreateHistory
        @StartDate = @StartingDate,
        @EndDate = @EndingDate,
        -- ... parameters
END;
```

### SQL Server-Specific Features Used

| Feature | Usage | PostgreSQL Equivalent |
|---------|-------|----------------------|
| `SYSDATETIME()` | High-precision timestamp | `clock_timestamp()` |
| `NEWID()` | Random GUID for shuffling | `gen_random_uuid()` |
| `HASHBYTES()` | Password hashing | `pgcrypto` extension |
| `NEXT VALUE FOR` | Sequence values | `nextval()` |
| `DATEADD()` | Date arithmetic | `+ INTERVAL` |
| `DATEDIFF()` | Date difference | `DATE_PART()` or subtraction |
| `PRINT` | Debug output | `RAISE NOTICE` |
| `SET NOCOUNT ON` | Suppress row counts | Not needed |

### Procedures Requiring Conversion

1. **Temporal Table Manipulation:**
   - `DeactivateTemporalTablesBeforeDataLoad`
   - `ReactivateTemporalTablesAfterDataLoad`

2. **Data Generation:**
   - `CreateCustomerOrders`
   - `InvoicePickedOrders`
   - `PickStockForCustomerOrders`
   - All 41 procedures in the schema

### Complexity: HIGH

These procedures are interconnected and must be converted as a unit. The temporal table manipulation procedures will need complete redesign.

---

## 4. SSIS Packages (ETL Replacement)

### Challenge Description

The `wwi-ssis` project contains SQL Server Integration Services packages for ETL from OLTP to OLAP database. SSIS is not available in PostgreSQL.

### Package Structure

```
wwi-ssis/
├── Daily ETL/
│   ├── Daily ETL.dtproj
│   ├── Daily ETL.ispac
│   └── Daily ETL.dtsx
└── README.md
```

### ETL Workflow

1. **Expression Task:** Calculate cutoff time
2. **Populate Date Dimension:** Ensure all dates for current year exist
3. **Load Dimensions:** City, Customer, Employee, Payment Method, Stock Item, Supplier, Transaction Type
4. **Load Facts:** Sale, Order, Purchase, Movement, Transaction, Stock Holding

### Migration Options

| Option | Pros | Cons |
|--------|------|------|
| **Apache Airflow** | Industry standard, Python-based, rich ecosystem | Additional infrastructure |
| **dbt (data build tool)** | SQL-based transformations, version control | Limited orchestration |
| **pg_cron + PL/pgSQL** | Native PostgreSQL, no external dependencies | Limited monitoring |
| **Prefect/Dagster** | Modern Python orchestration | Learning curve |

### Recommended Approach

1. Convert SSIS data flows to PostgreSQL stored procedures
2. Use `pg_cron` extension for scheduling
3. Implement logging and error handling in PL/pgSQL
4. Consider dbt for transformation logic

### Complexity: HIGH

The ETL logic must be completely rewritten. The Integration schema procedures provide the source queries but the orchestration layer needs replacement.

---

## 5. Row-Level Security (RLS)

### Challenge Description

SQL Server implements RLS using security policies and predicate functions. PostgreSQL has native RLS support but with different syntax.

### Current Implementation

**Security Policy:**
```sql
CREATE SECURITY POLICY [Application].FilterCustomersBySalesTerritoryRole
ADD FILTER PREDICATE [Application].DetermineCustomerAccess(DeliveryCityID)
ON Sales.Customers,
ADD BLOCK PREDICATE [Application].DetermineCustomerAccess(DeliveryCityID)
ON Sales.Customers AFTER UPDATE;
```

**Predicate Function:**
```sql
CREATE FUNCTION [Application].DetermineCustomerAccess(@CityID int)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN (SELECT 1 AS AccessResult
        WHERE IS_ROLEMEMBER(N'db_owner') <> 0
        OR IS_ROLEMEMBER((SELECT sp.SalesTerritory
                          FROM [Application].Cities AS c
                          INNER JOIN [Application].StateProvinces AS sp
                          ON c.StateProvinceID = sp.StateProvinceID
                          WHERE c.CityID = @CityID) + N' Sales') <> 0
        OR (ORIGINAL_LOGIN() = N'Website'
            AND EXISTS (SELECT 1
                        FROM [Application].Cities AS c
                        INNER JOIN [Application].StateProvinces AS sp
                        ON c.StateProvinceID = sp.StateProvinceID
                        WHERE c.CityID = @CityID
                        AND sp.SalesTerritory = SESSION_CONTEXT(N'SalesTerritory'))));
```

### SQL Server-Specific Functions

| Function | Purpose | PostgreSQL Equivalent |
|----------|---------|----------------------|
| `IS_ROLEMEMBER()` | Check role membership | `pg_has_role()` |
| `ORIGINAL_LOGIN()` | Get original login name | `session_user` |
| `SESSION_CONTEXT()` | Get session variable | `current_setting()` |

### PostgreSQL RLS Implementation

```sql
-- Enable RLS on table
ALTER TABLE sales.customers ENABLE ROW LEVEL SECURITY;

-- Create policy
CREATE POLICY customer_territory_policy ON sales.customers
    USING (
        pg_has_role(current_user, 'db_owner', 'MEMBER')
        OR pg_has_role(current_user, 
            (SELECT sp.sales_territory || ' Sales'
             FROM application.cities c
             JOIN application.state_provinces sp ON c.state_province_id = sp.state_province_id
             WHERE c.city_id = delivery_city_id), 'MEMBER')
        OR (session_user = 'website' 
            AND EXISTS (SELECT 1 FROM application.cities c
                       JOIN application.state_provinces sp ON c.state_province_id = sp.state_province_id
                       WHERE c.city_id = delivery_city_id
                       AND sp.sales_territory = current_setting('app.sales_territory')))
    );
```

### Complexity: MEDIUM

PostgreSQL has native RLS support, but the predicate logic needs adaptation for PostgreSQL's security model.

---

## 6. Full-Text Search

### Challenge Description

SQL Server uses full-text catalogs and the `CONTAINS` predicate. PostgreSQL uses `tsvector`/`tsquery` with GIN indexes.

### Current Implementation

**Full-Text Catalog:**
```sql
CREATE FULLTEXT CATALOG [FTCatalog] AS DEFAULT;
```

**Full-Text Index:**
```sql
CREATE FULLTEXT INDEX ON [Application].[People]
    ([SearchName], [CustomFields])
    KEY INDEX [PK_Application_People]
    ON [FTCatalog];
```

**Search Query:**
```sql
SELECT * FROM Application.People
WHERE CONTAINS(SearchName, @SearchText);
```

### PostgreSQL Equivalent

```sql
-- Add tsvector column
ALTER TABLE application.people 
ADD COLUMN search_vector tsvector;

-- Create GIN index
CREATE INDEX idx_people_search ON application.people USING GIN(search_vector);

-- Update trigger
CREATE TRIGGER people_search_update
BEFORE INSERT OR UPDATE ON application.people
FOR EACH ROW EXECUTE FUNCTION
tsvector_update_trigger(search_vector, 'pg_catalog.english', search_name, custom_fields);

-- Search query
SELECT * FROM application.people
WHERE search_vector @@ plainto_tsquery('english', @search_text);
```

### Complexity: MEDIUM

The conversion is straightforward but requires adding `tsvector` columns and updating search procedures.

---

## 7. Geography Data Type

### Challenge Description

SQL Server's `geography` type stores spatial data. PostgreSQL requires the PostGIS extension.

### Tables Using Geography

| Table | Column | Usage |
|-------|--------|-------|
| Application.Cities | Location | City coordinates |
| Application.StateProvinces | Border | State boundaries |
| Application.Countries | Border | Country boundaries |
| Sales.Customers | DeliveryLocation | Customer delivery point |
| Purchasing.Suppliers | DeliveryLocation | Supplier location |

### Migration Approach

1. Install PostGIS extension: `CREATE EXTENSION postgis;`
2. Convert `geography` columns to PostGIS `geography` type
3. Update spatial queries to use PostGIS functions

### SQL Server vs PostgreSQL Spatial Functions

| SQL Server | PostgreSQL (PostGIS) |
|------------|---------------------|
| `geography::Point()` | `ST_MakePoint()::geography` |
| `.STDistance()` | `ST_Distance()` |
| `.STIntersects()` | `ST_Intersects()` |
| `.STBuffer()` | `ST_Buffer()` |

### Complexity: LOW-MEDIUM

PostGIS provides equivalent functionality, but syntax differs.

---

## 8. JSON Functions

### Challenge Description

SQL Server 2016+ has JSON support, but function names differ from PostgreSQL.

### JSON Functions Used

| SQL Server | PostgreSQL | Usage |
|------------|------------|-------|
| `JSON_QUERY()` | `->` or `#>` | Extract JSON object/array |
| `JSON_VALUE()` | `->>` or `#>>` | Extract scalar value |
| `JSON_MODIFY()` | `jsonb_set()` | Update JSON |
| `OPENJSON()` | `jsonb_array_elements()` | Parse JSON array |
| `ISJSON()` | `jsonb_typeof() IS NOT NULL` | Validate JSON |

### Tables with JSON Columns

| Table | Column | Content |
|-------|--------|---------|
| Application.People | CustomFields | Employee attributes |
| Application.People | UserPreferences | User settings |
| Warehouse.StockItems | CustomFields | Product attributes |
| Sales.Invoices | ReturnedDeliveryData | Delivery events |

### Computed Columns from JSON

```sql
-- SQL Server
[OtherLanguages] AS (json_query([CustomFields],N'$.OtherLanguages'))

-- PostgreSQL (generated column)
other_languages text GENERATED ALWAYS AS (custom_fields->>'OtherLanguages') STORED
```

### Complexity: LOW-MEDIUM

PostgreSQL has excellent JSON support; mainly syntax conversion needed.

---

## 9. Sequences and Identity

### Challenge Description

SQL Server uses both `IDENTITY` columns and `SEQUENCE` objects. The WWI database uses sequences with `NEXT VALUE FOR` in default constraints.

### Current Pattern

```sql
-- Sequence definition
CREATE SEQUENCE [Sequences].[CustomerID] AS INT START WITH 1;

-- Table with sequence default
CREATE TABLE [Sales].[Customers] (
    [CustomerID] INT CONSTRAINT [DF_Sales_Customers_CustomerID] 
        DEFAULT (NEXT VALUE FOR [Sequences].[CustomerID]) NOT NULL,
    ...
);
```

### PostgreSQL Equivalent

```sql
-- Sequence definition
CREATE SEQUENCE sequences.customer_id START WITH 1;

-- Table with sequence default
CREATE TABLE sales.customers (
    customer_id INT DEFAULT nextval('sequences.customer_id') NOT NULL,
    ...
);
```

### Complexity: LOW

Direct mapping available; mainly syntax conversion.

---

## 10. Columnstore Indexes (OLAP Database)

### Challenge Description

SQL Server's clustered columnstore indexes provide columnar storage for analytics. PostgreSQL does not have native columnstore support.

### Tables with Columnstore Indexes

| Table | Index |
|-------|-------|
| Fact.Sale | CCX_Fact_Sale |
| Fact.Order | CCX_Fact_Order |
| Fact.Purchase | CCX_Fact_Purchase |
| Fact.Movement | CCX_Fact_Movement |
| Fact.Transaction | CCX_Fact_Transaction |
| Fact.Stock Holding | CCX_Fact_Stock_Holding |

### Migration Options

| Option | Description |
|--------|-------------|
| **Standard B-tree indexes** | Default PostgreSQL indexing |
| **BRIN indexes** | Block Range INdexes for large sequential data |
| **Citus extension** | Columnar storage for PostgreSQL |
| **TimescaleDB** | Time-series optimized storage |

### Recommended Approach

1. Use standard PostgreSQL tables with appropriate indexes
2. Consider BRIN indexes for date-partitioned fact tables
3. Evaluate Citus columnar for large analytical workloads

### Complexity: MEDIUM

Performance testing required to ensure acceptable query performance.

---

## 11. Table Partitioning (OLAP Database)

### Challenge Description

SQL Server uses partition functions and schemes. PostgreSQL uses declarative partitioning (PostgreSQL 10+).

### Current Implementation

```sql
-- Partition function
CREATE PARTITION FUNCTION [PF_Date](DATE) AS RANGE RIGHT FOR VALUES
    ('2013-01-01', '2014-01-01', '2015-01-01', '2016-01-01', 
     '2017-01-01', '2018-01-01', '2019-01-01');

-- Partition scheme
CREATE PARTITION SCHEME [PS_Date] AS PARTITION [PF_Date]
    TO ([USERDATA], [USERDATA], ...);

-- Partitioned table
CREATE TABLE [Fact].[Sale] (
    ...
    CONSTRAINT [PK_Fact_Sale] PRIMARY KEY NONCLUSTERED 
        ([Sale Key] ASC, [Invoice Date Key] ASC) ON [PS_Date] ([Invoice Date Key])
) ON [PS_Date] ([Invoice Date Key]);
```

### PostgreSQL Equivalent

```sql
-- Partitioned table
CREATE TABLE fact.sale (
    sale_key BIGINT,
    invoice_date_key DATE,
    ...
) PARTITION BY RANGE (invoice_date_key);

-- Partitions
CREATE TABLE fact.sale_2013 PARTITION OF fact.sale
    FOR VALUES FROM ('2013-01-01') TO ('2014-01-01');
CREATE TABLE fact.sale_2014 PARTITION OF fact.sale
    FOR VALUES FROM ('2014-01-01') TO ('2015-01-01');
-- ... additional partitions
```

### Complexity: MEDIUM

PostgreSQL's declarative partitioning is more straightforward but requires explicit partition creation.

---

## Summary of Migration Complexity

| Challenge | Complexity | Effort Estimate |
|-----------|------------|-----------------|
| Temporal Tables | HIGH | 3-4 weeks |
| Memory-Optimized Tables | MEDIUM-HIGH | 1-2 weeks |
| DataLoadSimulation Procedures | HIGH | 2-3 weeks |
| SSIS ETL Replacement | HIGH | 3-4 weeks |
| Row-Level Security | MEDIUM | 1 week |
| Full-Text Search | MEDIUM | 1 week |
| Geography Data Type | LOW-MEDIUM | 3-5 days |
| JSON Functions | LOW-MEDIUM | 3-5 days |
| Sequences and Identity | LOW | 1-2 days |
| Columnstore Indexes | MEDIUM | 1 week |
| Table Partitioning | MEDIUM | 1 week |

**Total Estimated Effort: 14-20 weeks** (for a single developer)

## Recommended Migration Order

1. **Phase 1:** Schema migration (tables, sequences, constraints)
2. **Phase 2:** Temporal table infrastructure (triggers, history tables)
3. **Phase 3:** Stored procedures and functions
4. **Phase 4:** Security (RLS, roles)
5. **Phase 5:** ETL replacement
6. **Phase 6:** Data migration
7. **Phase 7:** Performance optimization and testing
