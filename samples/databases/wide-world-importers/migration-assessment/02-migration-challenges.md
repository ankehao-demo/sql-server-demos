# Wide World Importers - Migration Challenges Document

## Executive Summary

This document details the specific migration challenges for converting the Wide World Importers database from SQL Server to PostgreSQL. Each challenge includes specific file references, complexity assessment, and recommended PostgreSQL alternatives.

---

## Challenge Categories

| Category | Count | Complexity | Priority |
|----------|-------|------------|----------|
| Temporal Tables | 17 tables | High | P1 |
| Memory-Optimized Tables | 2 tables + 4 types | High | P1 |
| Row-Level Security | 1 policy | Medium | P2 |
| Dynamic Data Masking | 5 columns | Medium | P2 |
| Stored Procedures | 50+ procedures | High | P1 |
| Full-Text Search | 4 tables | Medium | P2 |
| Geography Data Type | 5 tables | Medium | P2 |
| JSON Functions | Multiple tables | Low | P3 |
| Columnstore Indexes | 7 indexes | Medium | P2 |
| Partitioning | 6 tables | Medium | P2 |
| SSIS ETL Packages | 1 package | High | P1 |
| SSAS Cubes | 1 cube | High | P1 |
| Sequences | 26 sequences | Low | P3 |

---

## 1. Temporal Tables Migration

### Challenge Description

SQL Server's temporal tables (system-versioned tables) automatically track data changes over time. PostgreSQL does not have native temporal table support and requires a custom implementation using triggers and history tables.

### Affected Files

**OLTP Database (17 temporal tables):**

| Schema | Table | File Location |
|--------|-------|---------------|
| Application | Cities | `wwi-ssdt/wwi-ssdt/Application/Tables/Cities.sql` |
| Application | Countries | `wwi-ssdt/wwi-ssdt/Application/Tables/Countries.sql` |
| Application | DeliveryMethods | `wwi-ssdt/wwi-ssdt/Application/Tables/DeliveryMethods.sql` |
| Application | PaymentMethods | `wwi-ssdt/wwi-ssdt/Application/Tables/PaymentMethods.sql` |
| Application | People | `wwi-ssdt/wwi-ssdt/Application/Tables/People.sql` |
| Application | StateProvinces | `wwi-ssdt/wwi-ssdt/Application/Tables/StateProvinces.sql` |
| Application | TransactionTypes | `wwi-ssdt/wwi-ssdt/Application/Tables/TransactionTypes.sql` |
| Purchasing | SupplierCategories | `wwi-ssdt/wwi-ssdt/Purchasing/Tables/SupplierCategories.sql` |
| Purchasing | Suppliers | `wwi-ssdt/wwi-ssdt/Purchasing/Tables/Suppliers.sql` |
| Sales | BuyingGroups | `wwi-ssdt/wwi-ssdt/Sales/Tables/BuyingGroups.sql` |
| Sales | CustomerCategories | `wwi-ssdt/wwi-ssdt/Sales/Tables/CustomerCategories.sql` |
| Sales | Customers | `wwi-ssdt/wwi-ssdt/Sales/Tables/Customers.sql` |
| Warehouse | ColdRoomTemperatures | `wwi-ssdt/wwi-ssdt/Warehouse/Tables/ColdRoomTemperatures.sql` |
| Warehouse | Colors | `wwi-ssdt/wwi-ssdt/Warehouse/Tables/Colors.sql` |
| Warehouse | PackageTypes | `wwi-ssdt/wwi-ssdt/Warehouse/Tables/PackageTypes.sql` |
| Warehouse | StockGroups | `wwi-ssdt/wwi-ssdt/Warehouse/Tables/StockGroups.sql` |
| Warehouse | StockItems | `wwi-ssdt/wwi-ssdt/Warehouse/Tables/StockItems.sql` |

### SQL Server Syntax Example

From `wwi-ssdt/wwi-ssdt/Application/Tables/Cities.sql`:
```sql
CREATE TABLE [Application].[Cities] (
    [CityID] INT NOT NULL,
    [CityName] NVARCHAR (50) NOT NULL,
    [StateProvinceID] INT NOT NULL,
    [Location] [sys].[geography] NULL,
    [LatestRecordedPopulation] BIGINT NULL,
    [LastEditedBy] INT NOT NULL,
    [ValidFrom] DATETIME2 (7) GENERATED ALWAYS AS ROW START NOT NULL,
    [ValidTo] DATETIME2 (7) GENERATED ALWAYS AS ROW END NOT NULL,
    PERIOD FOR SYSTEM_TIME ([ValidFrom], [ValidTo])
)
WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE=[Application].[Cities_Archive], DATA_CONSISTENCY_CHECK=ON));
```

### PostgreSQL Migration Strategy

**Option 1: Trigger-Based Implementation (Recommended)**

```sql
-- Main table
CREATE TABLE application.cities (
    city_id INTEGER PRIMARY KEY,
    city_name VARCHAR(50) NOT NULL,
    state_province_id INTEGER NOT NULL,
    location GEOGRAPHY(POINT, 4326),
    latest_recorded_population BIGINT,
    last_edited_by INTEGER NOT NULL,
    valid_from TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    valid_to TIMESTAMP(6) NOT NULL DEFAULT '9999-12-31 23:59:59.999999'
);

-- History table
CREATE TABLE application.cities_archive (
    city_id INTEGER NOT NULL,
    city_name VARCHAR(50) NOT NULL,
    state_province_id INTEGER NOT NULL,
    location GEOGRAPHY(POINT, 4326),
    latest_recorded_population BIGINT,
    last_edited_by INTEGER NOT NULL,
    valid_from TIMESTAMP(6) NOT NULL,
    valid_to TIMESTAMP(6) NOT NULL
);

-- Trigger function
CREATE OR REPLACE FUNCTION application.cities_versioning()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        INSERT INTO application.cities_archive
        SELECT OLD.*, OLD.valid_from, CURRENT_TIMESTAMP;
        NEW.valid_from = CURRENT_TIMESTAMP;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO application.cities_archive
        SELECT OLD.*, OLD.valid_from, CURRENT_TIMESTAMP;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Trigger
CREATE TRIGGER cities_versioning_trigger
BEFORE UPDATE OR DELETE ON application.cities
FOR EACH ROW EXECUTE FUNCTION application.cities_versioning();
```

**Option 2: temporal_tables Extension**

The `temporal_tables` PostgreSQL extension provides similar functionality but requires installation and configuration.

### Related Stored Procedures to Modify

- `wwi-ssdt/wwi-ssdt/DataLoadSimulation/Stored Procedures/DeactivateTemporalTablesBeforeDataLoad.sql`
- `wwi-ssdt/wwi-ssdt/DataLoadSimulation/Stored Procedures/ReactivateTemporalTablesAfterDataLoad.sql`

### Complexity Assessment

- **Effort**: High (40+ hours)
- **Risk**: Medium (well-understood pattern)
- **Testing**: Extensive testing required for data consistency

---

## 2. Memory-Optimized Tables Migration

### Challenge Description

SQL Server's In-Memory OLTP feature provides memory-optimized tables for high-performance scenarios. PostgreSQL does not have an equivalent feature, but can achieve similar performance through proper indexing, connection pooling, and caching strategies.

### Affected Files

**Memory-Optimized Tables:**

| Table | File Location | Features |
|-------|---------------|----------|
| Warehouse.ColdRoomTemperatures | `wwi-ssdt/wwi-ssdt/Warehouse/Tables/ColdRoomTemperatures.sql` | Memory-optimized + Temporal |
| Warehouse.VehicleTemperatures | `wwi-ssdt/wwi-ssdt/Warehouse/Tables/VehicleTemperatures.sql` | Memory-optimized only |

**Memory-Optimized Table Types:**

| Type | File Location |
|------|---------------|
| Website.OrderIDList | `wwi-ssdt/wwi-ssdt/Website/User Defined Types/OrderIDList.sql` |
| Website.OrderList | `wwi-ssdt/wwi-ssdt/Website/User Defined Types/OrderList.sql` |
| Website.OrderLineList | `wwi-ssdt/wwi-ssdt/Website/User Defined Types/OrderLineList.sql` |
| Website.SensorDataList | `wwi-ssdt/wwi-ssdt/Website/User Defined Types/SensorDataList.sql` |

**Configuration Procedures:**

| Procedure | File Location |
|-----------|---------------|
| Configuration_EnableInMemory | `wwi-ssdt/wwi-ssdt/Application/Stored Procedures/Configuration_EnableInMemory.sql` |
| Configuration_DisableInMemory | `wwi-ssdt/wwi-ssdt/Application/Stored Procedures/Configuration_DisableInMemory.sql` |

### SQL Server Syntax Example

From `wwi-ssdt/wwi-ssdt/Website/User Defined Types/SensorDataList.sql`:
```sql
CREATE TYPE [Website].[SensorDataList] AS TABLE (
    [SensorDataListID] INT IDENTITY (1, 1) NOT NULL,
    [ColdRoomSensorNumber] INT NULL,
    [RecordedWhen] DATETIME2 (7) NULL,
    [Temperature] DECIMAL (18, 2) NULL,
    PRIMARY KEY NONCLUSTERED ([SensorDataListID] ASC))
    WITH (MEMORY_OPTIMIZED = ON);
```

### PostgreSQL Migration Strategy

**For Memory-Optimized Tables:**

1. Convert to regular PostgreSQL tables with optimized indexes
2. Use `UNLOGGED` tables for non-critical high-performance scenarios (data not persisted across crashes)
3. Implement connection pooling (PgBouncer) for high-concurrency scenarios
4. Use Redis or Memcached for caching frequently accessed data

```sql
-- Option 1: Regular table with optimized indexes
CREATE TABLE warehouse.cold_room_temperatures (
    cold_room_temperature_id BIGSERIAL PRIMARY KEY,
    cold_room_sensor_number INTEGER NOT NULL,
    recorded_when TIMESTAMP(6) NOT NULL,
    temperature NUMERIC(10, 2) NOT NULL,
    valid_from TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    valid_to TIMESTAMP(6) NOT NULL DEFAULT '9999-12-31 23:59:59.999999'
);

CREATE INDEX idx_cold_room_sensor ON warehouse.cold_room_temperatures(cold_room_sensor_number);

-- Option 2: UNLOGGED table for non-critical high-performance (data lost on crash)
CREATE UNLOGGED TABLE warehouse.vehicle_temperatures (
    vehicle_temperature_id BIGSERIAL PRIMARY KEY,
    vehicle_registration VARCHAR(20) NOT NULL,
    chiller_sensor_number INTEGER NOT NULL,
    recorded_when TIMESTAMP(6) NOT NULL,
    temperature NUMERIC(18, 2) NOT NULL,
    full_sensor_data JSONB,
    is_compressed BOOLEAN NOT NULL DEFAULT FALSE,
    compressed_sensor_data BYTEA
);
```

**For Memory-Optimized Table Types:**

Convert to regular composite types or use temporary tables:

```sql
-- Option 1: Composite type (for function parameters)
CREATE TYPE website.sensor_data_list AS (
    sensor_data_list_id INTEGER,
    cold_room_sensor_number INTEGER,
    recorded_when TIMESTAMP(6),
    temperature NUMERIC(18, 2)
);

-- Option 2: Temporary table (for bulk operations)
CREATE TEMPORARY TABLE temp_sensor_data (
    sensor_data_list_id SERIAL PRIMARY KEY,
    cold_room_sensor_number INTEGER,
    recorded_when TIMESTAMP(6),
    temperature NUMERIC(18, 2)
) ON COMMIT DROP;
```

### Natively Compiled Procedures

The following natively compiled procedure needs conversion:

From `wwi-ssdt/wwi-ssdt/Application/Stored Procedures/Configuration_EnableInMemory.sql`:
```sql
CREATE PROCEDURE Website.RecordColdRoomTemperatures
@SensorReadings Website.SensorDataList READONLY
WITH NATIVE_COMPILATION, SCHEMABINDING, EXECUTE AS OWNER
AS
BEGIN ATOMIC WITH
(
    TRANSACTION ISOLATION LEVEL = SNAPSHOT,
    LANGUAGE = N'English'
)
    -- procedure body
END;
```

PostgreSQL equivalent:
```sql
CREATE OR REPLACE FUNCTION website.record_cold_room_temperatures(
    p_sensor_readings website.sensor_data_list[]
)
RETURNS VOID AS $$
BEGIN
    INSERT INTO warehouse.cold_room_temperatures (
        cold_room_sensor_number, recorded_when, temperature
    )
    SELECT 
        (unnest).cold_room_sensor_number,
        (unnest).recorded_when,
        (unnest).temperature
    FROM unnest(p_sensor_readings);
END;
$$ LANGUAGE plpgsql;
```

### Complexity Assessment

- **Effort**: High (30+ hours)
- **Risk**: High (performance characteristics will differ)
- **Testing**: Performance benchmarking required

---

## 3. Row-Level Security Migration

### Challenge Description

SQL Server's Row-Level Security (RLS) uses security policies with filter and block predicates. PostgreSQL has native RLS support but with different syntax.

### Affected Files

| Component | File Location |
|-----------|---------------|
| Security Policy | `wwi-ssdt/wwi-ssdt/Security/FilterCustomersBySalesTerritoryRole.sql` |
| Predicate Function | `wwi-ssdt/wwi-ssdt/Application/Functions/DetermineCustomerAccess.sql` |
| Configuration Procedure | `wwi-ssdt/wwi-ssdt/Application/Stored Procedures/Configuration_ApplyRowLevelSecurity.sql` |
| Removal Procedure | `wwi-ssdt/wwi-ssdt/Application/Stored Procedures/Configuration_RemoveRowLevelSecurity.sql` |

### SQL Server Syntax

From `wwi-ssdt/wwi-ssdt/Application/Functions/DetermineCustomerAccess.sql`:
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
        OR ((ORIGINAL_LOGIN() = N'Website' OR ORIGINAL_LOGIN() = N'WebApi')
            AND EXISTS (SELECT 1
                        FROM [Application].Cities AS c
                        INNER JOIN [Application].StateProvinces AS sp
                        ON c.StateProvinceID = sp.StateProvinceID
                        WHERE c.CityID = @CityID
                        AND sp.SalesTerritory = SESSION_CONTEXT(N'SalesTerritory'))));
```

From `wwi-ssdt/wwi-ssdt/Security/FilterCustomersBySalesTerritoryRole.sql`:
```sql
CREATE SECURITY POLICY [Application].[FilterCustomersBySalesTerritoryRole]
    ADD FILTER PREDICATE [Application].[DetermineCustomerAccess]([DeliveryCityID]) ON [Sales].[Customers],
    ADD BLOCK PREDICATE [Application].[DetermineCustomerAccess]([DeliveryCityID]) ON [Sales].[Customers] AFTER UPDATE
    WITH (STATE = ON);
```

### PostgreSQL Migration Strategy

```sql
-- Enable RLS on the table
ALTER TABLE sales.customers ENABLE ROW LEVEL SECURITY;

-- Create the policy function
CREATE OR REPLACE FUNCTION application.determine_customer_access(city_id INTEGER)
RETURNS BOOLEAN AS $$
DECLARE
    sales_territory TEXT;
    session_territory TEXT;
BEGIN
    -- Check if user is superuser or db_owner equivalent
    IF current_user = 'postgres' OR pg_has_role(current_user, 'db_owner', 'MEMBER') THEN
        RETURN TRUE;
    END IF;
    
    -- Get the sales territory for the city
    SELECT sp.sales_territory INTO sales_territory
    FROM application.cities c
    INNER JOIN application.state_provinces sp ON c.state_province_id = sp.state_province_id
    WHERE c.city_id = city_id;
    
    -- Check if user is member of the territory sales role
    IF pg_has_role(current_user, sales_territory || ' Sales', 'MEMBER') THEN
        RETURN TRUE;
    END IF;
    
    -- Check for Website/WebApi users with session context
    IF current_user IN ('website', 'webapi') THEN
        session_territory := current_setting('app.sales_territory', TRUE);
        IF session_territory IS NOT NULL AND session_territory = sales_territory THEN
            RETURN TRUE;
        END IF;
    END IF;
    
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create the RLS policy
CREATE POLICY customer_territory_policy ON sales.customers
    USING (application.determine_customer_access(delivery_city_id))
    WITH CHECK (application.determine_customer_access(delivery_city_id));

-- Set session context (equivalent to SESSION_CONTEXT)
SET app.sales_territory = 'Great Lakes';
```

### Complexity Assessment

- **Effort**: Medium (15-20 hours)
- **Risk**: Medium (PostgreSQL has native RLS support)
- **Testing**: Security testing required

---

## 4. Dynamic Data Masking Migration

### Challenge Description

SQL Server's Dynamic Data Masking automatically masks sensitive data for non-privileged users. PostgreSQL does not have native dynamic data masking but can implement similar functionality using views or the `anon` extension.

### Affected Files

| Table | Masked Columns | File Location |
|-------|----------------|---------------|
| Purchasing.Suppliers | BankAccountName, BankAccountBranch, BankAccountCode, BankAccountNumber, BankInternationalCode | `wwi-ssdt/wwi-ssdt/Purchasing/Tables/Suppliers.sql` |

### SQL Server Syntax

From `wwi-ssdt/wwi-ssdt/Purchasing/Tables/Suppliers.sql`:
```sql
[BankAccountName]       NVARCHAR (50) MASKED WITH (FUNCTION = 'default()') NULL,
[BankAccountBranch]     NVARCHAR (50) MASKED WITH (FUNCTION = 'default()') NULL,
[BankAccountCode]       NVARCHAR (20) MASKED WITH (FUNCTION = 'default()') NULL,
[BankAccountNumber]     NVARCHAR (20) MASKED WITH (FUNCTION = 'default()') NULL,
[BankInternationalCode] NVARCHAR (20) MASKED WITH (FUNCTION = 'default()') NULL,
```

### PostgreSQL Migration Strategy

**Option 1: View-Based Masking (Recommended)**

```sql
-- Create a masking function
CREATE OR REPLACE FUNCTION purchasing.mask_bank_data(value TEXT)
RETURNS TEXT AS $$
BEGIN
    IF pg_has_role(current_user, 'unmask_bank_data', 'MEMBER') THEN
        RETURN value;
    ELSE
        RETURN 'XXXX';
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create a view with masking
CREATE OR REPLACE VIEW purchasing.suppliers_masked AS
SELECT 
    supplier_id,
    supplier_name,
    supplier_category_id,
    primary_contact_person_id,
    alternate_contact_person_id,
    delivery_method_id,
    delivery_city_id,
    postal_city_id,
    supplier_reference,
    purchasing.mask_bank_data(bank_account_name) AS bank_account_name,
    purchasing.mask_bank_data(bank_account_branch) AS bank_account_branch,
    purchasing.mask_bank_data(bank_account_code) AS bank_account_code,
    purchasing.mask_bank_data(bank_account_number) AS bank_account_number,
    purchasing.mask_bank_data(bank_international_code) AS bank_international_code,
    payment_days,
    internal_comments,
    phone_number,
    fax_number,
    website_url,
    delivery_address_line1,
    delivery_address_line2,
    delivery_postal_code,
    delivery_location,
    postal_address_line1,
    postal_address_line2,
    postal_postal_code,
    last_edited_by,
    valid_from,
    valid_to
FROM purchasing.suppliers;

-- Grant access to the view instead of the table
REVOKE ALL ON purchasing.suppliers FROM PUBLIC;
GRANT SELECT ON purchasing.suppliers_masked TO application_users;
```

**Option 2: PostgreSQL Anonymizer Extension**

```sql
-- Install the anon extension
CREATE EXTENSION IF NOT EXISTS anon CASCADE;

-- Define masking rules
SELECT anon.init();

SECURITY LABEL FOR anon ON COLUMN purchasing.suppliers.bank_account_name
IS 'MASKED WITH FUNCTION anon.partial(bank_account_name, 0, ''XXXX'', 0)';

SECURITY LABEL FOR anon ON COLUMN purchasing.suppliers.bank_account_number
IS 'MASKED WITH FUNCTION anon.partial(bank_account_number, 0, ''XXXX'', 0)';
```

### Complexity Assessment

- **Effort**: Low-Medium (10-15 hours)
- **Risk**: Low (well-understood pattern)
- **Testing**: Security testing required

---

## 5. Stored Procedures Migration (T-SQL to PL/pgSQL)

### Challenge Description

Converting T-SQL stored procedures to PL/pgSQL requires significant syntax changes and logic adaptation.

### Key Syntax Differences

| Feature | T-SQL | PL/pgSQL |
|---------|-------|----------|
| Variable declaration | `DECLARE @var INT` | `var INTEGER;` in DECLARE block |
| Assignment | `SET @var = 1` or `SELECT @var = col` | `var := 1;` or `SELECT col INTO var` |
| String concatenation | `+` or `CONCAT()` | `||` |
| NULL handling | `ISNULL()` | `COALESCE()` |
| Date functions | `GETDATE()`, `SYSDATETIME()` | `CURRENT_TIMESTAMP`, `NOW()` |
| Date arithmetic | `DATEADD(day, 1, @date)` | `date + INTERVAL '1 day'` |
| Error handling | `TRY...CATCH` | `BEGIN...EXCEPTION...END` |
| Dynamic SQL | `EXEC(@sql)` or `sp_executesql` | `EXECUTE sql` |
| Temp tables | `#temp` | `CREATE TEMP TABLE` |
| Table variables | `DECLARE @t TABLE(...)` | `CREATE TEMP TABLE` or arrays |
| OUTPUT parameters | `@param OUTPUT` | `OUT param` or `INOUT param` |
| JSON output | `FOR JSON AUTO` | `json_agg()`, `row_to_json()` |

### High-Priority Procedures to Convert

**Data Generation Procedures:**

| Procedure | File Location | Complexity |
|-----------|---------------|------------|
| PopulateDataToCurrentDate | `wwi-ssdt/wwi-ssdt/DataLoadSimulation/Stored Procedures/PopulateDataToCurrentDate.sql` | Very High |
| DailyProcessToCreateHistory | `wwi-ssdt/wwi-ssdt/DataLoadSimulation/Stored Procedures/DailyProcessToCreateHistory.sql` | High |
| CreateCustomerOrders | `wwi-ssdt/wwi-ssdt/DataLoadSimulation/Stored Procedures/CreateCustomerOrders.sql` | High |

**Website Procedures:**

| Procedure | File Location | Complexity |
|-----------|---------------|------------|
| SearchForPeople | `wwi-ssdt/wwi-ssdt/Website/Stored Procedures/SearchForPeople.sql` | Medium |
| SearchForCustomers | `wwi-ssdt/wwi-ssdt/Website/Stored Procedures/SearchForCustomers.sql` | Medium |
| SearchForStockItems | `wwi-ssdt/wwi-ssdt/Website/Stored Procedures/SearchForStockItems.sql` | Medium |
| InvoiceCustomerOrders | `wwi-ssdt/wwi-ssdt/Website/Stored Procedures/InvoiceCustomerOrders.sql` | High |
| InsertCustomerOrders | `wwi-ssdt/wwi-ssdt/Website/Stored Procedures/InsertCustomerOrders.sql` | High |

**Configuration Procedures:**

| Procedure | File Location | Complexity |
|-----------|---------------|------------|
| Configuration_ApplyRowLevelSecurity | `wwi-ssdt/wwi-ssdt/Application/Stored Procedures/Configuration_ApplyRowLevelSecurity.sql` | Medium |
| Configuration_ApplyFullTextIndexing | `wwi-ssdt/wwi-ssdt/Application/Stored Procedures/Configuration_ApplyFullTextIndexing.sql` | Medium |

### Example Conversion

**T-SQL (from SearchForStockItems.sql):**
```sql
CREATE PROCEDURE Website.SearchForStockItems
@SearchText nvarchar(1000),
@MaximumRowsToReturn int
WITH EXECUTE AS OWNER
AS
BEGIN
    SELECT TOP(@MaximumRowsToReturn)
           si.StockItemID,
           si.StockItemName
    FROM Warehouse.StockItems AS si
    WHERE si.SearchDetails LIKE N'%' + @SearchText + N'%'
    ORDER BY si.StockItemName
    FOR JSON AUTO, ROOT(N'StockItems');
END;
```

**PL/pgSQL Equivalent:**
```sql
CREATE OR REPLACE FUNCTION website.search_for_stock_items(
    p_search_text TEXT,
    p_maximum_rows_to_return INTEGER
)
RETURNS JSON
SECURITY DEFINER
AS $$
BEGIN
    RETURN (
        SELECT json_build_object(
            'StockItems',
            COALESCE(json_agg(
                json_build_object(
                    'StockItemID', si.stock_item_id,
                    'StockItemName', si.stock_item_name
                )
            ), '[]'::json)
        )
        FROM (
            SELECT si.stock_item_id, si.stock_item_name
            FROM warehouse.stock_items si
            WHERE si.search_details ILIKE '%' || p_search_text || '%'
            ORDER BY si.stock_item_name
            LIMIT p_maximum_rows_to_return
        ) si
    );
END;
$$ LANGUAGE plpgsql;
```

### Complexity Assessment

- **Effort**: Very High (100+ hours for all procedures)
- **Risk**: High (logic errors possible)
- **Testing**: Comprehensive unit testing required

---

## 6. Full-Text Search Migration

### Challenge Description

SQL Server's Full-Text Search uses `FREETEXTTABLE`, `CONTAINSTABLE`, and full-text catalogs. PostgreSQL uses `tsvector`, `tsquery`, and GIN indexes.

### Affected Files

| Component | File Location |
|-----------|---------------|
| Full-Text Configuration | `wwi-ssdt/wwi-ssdt/Application/Stored Procedures/Configuration_ApplyFullTextIndexing.sql` |
| Search Procedures | `wwi-ssdt/wwi-ssdt/Website/Stored Procedures/SearchFor*.sql` |

### Tables with Full-Text Indexes

| Table | Indexed Columns |
|-------|-----------------|
| Application.People | SearchName, CustomFields, OtherLanguages |
| Sales.Customers | CustomerName |
| Purchasing.Suppliers | SupplierName |
| Warehouse.StockItems | SearchDetails, CustomFields, Tags |

### SQL Server Syntax

From `Configuration_ApplyFullTextIndexing.sql`:
```sql
CREATE FULLTEXT CATALOG FTCatalog AS DEFAULT;

CREATE FULLTEXT INDEX
ON [Application].People (SearchName, CustomFields, OtherLanguages)
KEY INDEX PK_Application_People
WITH CHANGE_TRACKING AUTO;
```

Search query:
```sql
SELECT p.PersonID, p.FullName
FROM [Application].People AS p
INNER JOIN FREETEXTTABLE([Application].People, SearchName, @SearchText, @MaximumRowsToReturn) AS ft
ON p.PersonID = ft.[KEY]
ORDER BY ft.[RANK];
```

### PostgreSQL Migration Strategy

```sql
-- Add tsvector column
ALTER TABLE application.people 
ADD COLUMN search_vector tsvector;

-- Create trigger to update search vector
CREATE OR REPLACE FUNCTION application.people_search_vector_update()
RETURNS TRIGGER AS $$
BEGIN
    NEW.search_vector := 
        setweight(to_tsvector('english', COALESCE(NEW.search_name, '')), 'A') ||
        setweight(to_tsvector('english', COALESCE(NEW.custom_fields::text, '')), 'B') ||
        setweight(to_tsvector('english', COALESCE(NEW.other_languages::text, '')), 'C');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER people_search_vector_trigger
BEFORE INSERT OR UPDATE ON application.people
FOR EACH ROW EXECUTE FUNCTION application.people_search_vector_update();

-- Create GIN index
CREATE INDEX idx_people_search ON application.people USING GIN(search_vector);

-- Search function
CREATE OR REPLACE FUNCTION website.search_for_people(
    p_search_text TEXT,
    p_max_rows INTEGER
)
RETURNS JSON AS $$
BEGIN
    RETURN (
        SELECT json_build_object('People', COALESCE(json_agg(row_to_json(t)), '[]'::json))
        FROM (
            SELECT 
                p.person_id,
                p.full_name,
                p.preferred_name,
                ts_rank(p.search_vector, plainto_tsquery('english', p_search_text)) AS rank
            FROM application.people p
            WHERE p.search_vector @@ plainto_tsquery('english', p_search_text)
            ORDER BY rank DESC
            LIMIT p_max_rows
        ) t
    );
END;
$$ LANGUAGE plpgsql;
```

### Complexity Assessment

- **Effort**: Medium (20-30 hours)
- **Risk**: Medium (different ranking algorithms)
- **Testing**: Search quality testing required

---

## 7. Geography Data Type Migration

### Challenge Description

SQL Server's `geography` data type needs to be converted to PostGIS `geography` type.

### Affected Tables

| Table | Column | File Location |
|-------|--------|---------------|
| Application.Cities | Location | `wwi-ssdt/wwi-ssdt/Application/Tables/Cities.sql` |
| Application.Countries | Border | `wwi-ssdt/wwi-ssdt/Application/Tables/Countries.sql` |
| Application.StateProvinces | Border | `wwi-ssdt/wwi-ssdt/Application/Tables/StateProvinces.sql` |
| Sales.Customers | DeliveryLocation | `wwi-ssdt/wwi-ssdt/Sales/Tables/Customers.sql` |
| Purchasing.Suppliers | DeliveryLocation | `wwi-ssdt/wwi-ssdt/Purchasing/Tables/Suppliers.sql` |

### PostgreSQL Migration Strategy

```sql
-- Enable PostGIS extension
CREATE EXTENSION IF NOT EXISTS postgis;

-- Create table with geography type
CREATE TABLE application.cities (
    city_id INTEGER PRIMARY KEY,
    city_name VARCHAR(50) NOT NULL,
    state_province_id INTEGER NOT NULL,
    location GEOGRAPHY(POINT, 4326),  -- SRID 4326 = WGS84
    latest_recorded_population BIGINT,
    last_edited_by INTEGER NOT NULL,
    valid_from TIMESTAMP(6) NOT NULL,
    valid_to TIMESTAMP(6) NOT NULL
);

-- Create spatial index
CREATE INDEX idx_cities_location ON application.cities USING GIST(location);

-- Example spatial query
SELECT city_name, ST_Distance(location, ST_GeogFromText('POINT(-87.6298 41.8781)')) AS distance_meters
FROM application.cities
WHERE ST_DWithin(location, ST_GeogFromText('POINT(-87.6298 41.8781)'), 100000)
ORDER BY distance_meters;
```

### Complexity Assessment

- **Effort**: Low-Medium (10-15 hours)
- **Risk**: Low (PostGIS is mature and well-documented)
- **Testing**: Spatial query validation required

---

## 8. Columnstore Indexes Migration

### Challenge Description

SQL Server's columnstore indexes provide columnar storage for analytical queries. PostgreSQL does not have native columnstore indexes but can use extensions like `cstore_fdw` or `Citus` for columnar storage.

### Affected Tables

**OLTP Database:**

| Table | Index Type | File Location |
|-------|------------|---------------|
| Sales.OrderLines | Non-clustered columnstore | `wwi-ssdt/wwi-ssdt/Sales/Tables/OrderLines.sql` |

**OLAP Database:**

| Table | Index Type | File Location |
|-------|------------|---------------|
| Fact.Sale | Clustered columnstore | `wwi-dw-ssdt/wwi-dw-ssdt/Fact/Tables/Sale.sql` |
| Fact.Order | Clustered columnstore | `wwi-dw-ssdt/wwi-dw-ssdt/Fact/Tables/Order.sql` |
| Fact.Purchase | Clustered columnstore | `wwi-dw-ssdt/wwi-dw-ssdt/Fact/Tables/Purchase.sql` |
| Fact.Movement | Clustered columnstore | `wwi-dw-ssdt/wwi-dw-ssdt/Fact/Tables/Movement.sql` |
| Fact.Transaction | Clustered columnstore | `wwi-dw-ssdt/wwi-dw-ssdt/Fact/Tables/Transaction.sql` |
| Fact.Stock Holding | Clustered columnstore | `wwi-dw-ssdt/wwi-dw-ssdt/Fact/Tables/Stock Holding.sql` |

### PostgreSQL Migration Strategy

**Option 1: Standard PostgreSQL with Optimized Indexes**

For most use cases, standard PostgreSQL with proper BRIN indexes and partitioning can provide good analytical performance:

```sql
-- Create table with BRIN index for range queries
CREATE TABLE fact.sale (
    sale_key BIGSERIAL PRIMARY KEY,
    city_key INTEGER NOT NULL,
    customer_key INTEGER NOT NULL,
    stock_item_key INTEGER NOT NULL,
    invoice_date_key DATE NOT NULL,
    quantity INTEGER NOT NULL,
    unit_price NUMERIC(18,2) NOT NULL,
    total_excluding_tax NUMERIC(18,2) NOT NULL
) PARTITION BY RANGE (invoice_date_key);

-- Create BRIN index for date-based queries
CREATE INDEX idx_sale_date_brin ON fact.sale USING BRIN(invoice_date_key);

-- Create regular indexes for dimension keys
CREATE INDEX idx_sale_customer ON fact.sale(customer_key);
CREATE INDEX idx_sale_stock_item ON fact.sale(stock_item_key);
```

**Option 2: Citus Columnar (for large analytical workloads)**

```sql
-- Enable Citus extension
CREATE EXTENSION IF NOT EXISTS citus;

-- Create columnar table
CREATE TABLE fact.sale (
    sale_key BIGINT,
    city_key INTEGER,
    customer_key INTEGER,
    stock_item_key INTEGER,
    invoice_date_key DATE,
    quantity INTEGER,
    unit_price NUMERIC(18,2),
    total_excluding_tax NUMERIC(18,2)
) USING columnar;
```

### Complexity Assessment

- **Effort**: Medium (15-25 hours)
- **Risk**: Medium (performance characteristics will differ)
- **Testing**: Performance benchmarking required

---

## 9. Partitioning Migration

### Challenge Description

SQL Server uses partition functions and schemes. PostgreSQL uses declarative partitioning (PostgreSQL 10+) or inheritance-based partitioning.

### Affected Files

| Component | File Location |
|-----------|---------------|
| Partition Function | `wwi-dw-ssdt/wwi-dw-ssdt/Storage/PF_Date.sql` |
| Partition Scheme | `wwi-dw-ssdt/wwi-dw-ssdt/Storage/PS_Date.sql` |

### SQL Server Syntax

From `PF_Date.sql`:
```sql
CREATE PARTITION FUNCTION [PF_Date](DATE)
    AS RANGE RIGHT
    FOR VALUES ('01/01/2012', '01/01/2013', '01/01/2014', '01/01/2015', '01/01/2016', '01/01/2017');
```

From `PS_Date.sql`:
```sql
CREATE PARTITION SCHEME [PS_Date]
    AS PARTITION [PF_Date]
    TO ([USERDATA], [USERDATA], [USERDATA], [USERDATA], [USERDATA], [USERDATA], [USERDATA], [USERDATA]);
```

### PostgreSQL Migration Strategy

```sql
-- Create partitioned table
CREATE TABLE fact.sale (
    sale_key BIGSERIAL,
    city_key INTEGER NOT NULL,
    customer_key INTEGER NOT NULL,
    invoice_date_key DATE NOT NULL,
    quantity INTEGER NOT NULL,
    total_excluding_tax NUMERIC(18,2) NOT NULL,
    PRIMARY KEY (sale_key, invoice_date_key)
) PARTITION BY RANGE (invoice_date_key);

-- Create partitions
CREATE TABLE fact.sale_2012 PARTITION OF fact.sale
    FOR VALUES FROM ('2012-01-01') TO ('2013-01-01');
CREATE TABLE fact.sale_2013 PARTITION OF fact.sale
    FOR VALUES FROM ('2013-01-01') TO ('2014-01-01');
CREATE TABLE fact.sale_2014 PARTITION OF fact.sale
    FOR VALUES FROM ('2014-01-01') TO ('2015-01-01');
CREATE TABLE fact.sale_2015 PARTITION OF fact.sale
    FOR VALUES FROM ('2015-01-01') TO ('2016-01-01');
CREATE TABLE fact.sale_2016 PARTITION OF fact.sale
    FOR VALUES FROM ('2016-01-01') TO ('2017-01-01');
CREATE TABLE fact.sale_2017 PARTITION OF fact.sale
    FOR VALUES FROM ('2017-01-01') TO ('2018-01-01');
CREATE TABLE fact.sale_default PARTITION OF fact.sale DEFAULT;

-- Use pg_partman for automatic partition management
CREATE EXTENSION IF NOT EXISTS pg_partman;

SELECT partman.create_parent(
    p_parent_table := 'fact.sale',
    p_control := 'invoice_date_key',
    p_type := 'native',
    p_interval := '1 year'
);
```

### Complexity Assessment

- **Effort**: Medium (15-20 hours)
- **Risk**: Low (PostgreSQL has mature partitioning support)
- **Testing**: Query performance validation required

---

## 10. SSIS ETL Package Migration

### Challenge Description

SQL Server Integration Services (SSIS) packages need to be replaced with PostgreSQL-compatible ETL solutions.

### Affected Files

| Component | File Location |
|-----------|---------------|
| SSIS Project | `wwi-ssis/wwi-ssis/Daily ETL.dtproj` |
| Main ETL Package | `wwi-ssis/wwi-ssis/DailyETLMain.dtsx` |
| Source Connection | `wwi-ssis/wwi-ssis/WWI_Source_DB.conmgr` |
| Destination Connection | `wwi-ssis/wwi-ssis/WWI_DW_Destination_DB.conmgr` |

### PostgreSQL Migration Options

**Option 1: Apache Airflow (Recommended)**

```python
# Example Airflow DAG for WWI ETL
from airflow import DAG
from airflow.providers.postgres.operators.postgres import PostgresOperator
from datetime import datetime, timedelta

default_args = {
    'owner': 'wwi',
    'depends_on_past': False,
    'start_date': datetime(2024, 1, 1),
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

dag = DAG(
    'wwi_daily_etl',
    default_args=default_args,
    schedule_interval='@daily',
    catchup=False
)

# Extract and load city data
load_cities = PostgresOperator(
    task_id='load_cities',
    postgres_conn_id='wwi_dw',
    sql='CALL integration.migrate_staged_city_data();',
    dag=dag
)

# Extract and load customer data
load_customers = PostgresOperator(
    task_id='load_customers',
    postgres_conn_id='wwi_dw',
    sql='CALL integration.migrate_staged_customer_data();',
    dag=dag
)

load_cities >> load_customers
```

**Option 2: dbt (Data Build Tool)**

```yaml
# dbt project structure
models/
  staging/
    stg_cities.sql
    stg_customers.sql
  marts/
    dim_city.sql
    dim_customer.sql
    fact_sale.sql
```

**Option 3: PostgreSQL Native (pg_cron + Stored Procedures)**

```sql
-- Install pg_cron extension
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Schedule daily ETL
SELECT cron.schedule('daily_etl', '0 2 * * *', 'CALL integration.run_daily_etl();');

-- Main ETL procedure
CREATE OR REPLACE PROCEDURE integration.run_daily_etl()
AS $$
BEGIN
    CALL integration.migrate_staged_city_data();
    CALL integration.migrate_staged_customer_data();
    CALL integration.migrate_staged_employee_data();
    CALL integration.migrate_staged_stock_item_data();
    CALL integration.migrate_staged_supplier_data();
    CALL integration.migrate_staged_sale_data();
    CALL integration.migrate_staged_order_data();
    CALL integration.migrate_staged_purchase_data();
    CALL integration.migrate_staged_movement_data();
    CALL integration.migrate_staged_transaction_data();
END;
$$ LANGUAGE plpgsql;
```

### Complexity Assessment

- **Effort**: High (40-60 hours)
- **Risk**: Medium (well-understood ETL patterns)
- **Testing**: Data validation and reconciliation required

---

## 11. SSAS Cube Migration

### Challenge Description

SQL Server Analysis Services (SSAS) multidimensional cubes need to be replaced with PostgreSQL-compatible OLAP solutions.

### Affected Files

| Component | File Location |
|-----------|---------------|
| SSAS Project | `wwi-ssasmd/wwi-ssasmd/WideWorldImportersMultidimensionalCube.dwproj` |
| Cube Definition | `wwi-ssasmd/wwi-ssasmd/Wide World Importers.cube` |
| Dimensions | `wwi-ssasmd/wwi-ssasmd/*.dim` |
| Data Source | `wwi-ssasmd/wwi-ssasmd/WideWorldImportersDW.ds` |
| Data Source View | `wwi-ssasmd/wwi-ssasmd/Wide World Importers DW.dsv` |
| Partitions | `wwi-ssasmd/wwi-ssasmd/Wide World Importers.partitions` |

### PostgreSQL Migration Options

**Option 1: Apache Druid**

Druid provides real-time OLAP capabilities with sub-second queries on large datasets.

**Option 2: ClickHouse**

ClickHouse is a columnar database optimized for OLAP workloads.

**Option 3: PostgreSQL with Materialized Views**

For simpler use cases, PostgreSQL materialized views can provide pre-aggregated data:

```sql
-- Create materialized view for sales analysis
CREATE MATERIALIZED VIEW analytics.sales_by_territory AS
SELECT 
    d.calendar_year,
    d.calendar_month_label,
    c.sales_territory,
    s.stock_item_name,
    SUM(f.quantity) AS total_quantity,
    SUM(f.total_excluding_tax) AS total_revenue,
    SUM(f.profit) AS total_profit
FROM fact.sale f
JOIN dimension.date d ON f.invoice_date_key = d.date
JOIN dimension.city c ON f.city_key = c.city_key
JOIN dimension.stock_item s ON f.stock_item_key = s.stock_item_key
GROUP BY d.calendar_year, d.calendar_month_label, c.sales_territory, s.stock_item_name;

-- Create index for fast queries
CREATE INDEX idx_sales_territory ON analytics.sales_by_territory(sales_territory, calendar_year);

-- Refresh materialized view
REFRESH MATERIALIZED VIEW CONCURRENTLY analytics.sales_by_territory;
```

**Option 4: Apache Superset for Visualization**

Replace SSAS cube browsing with Apache Superset dashboards connected directly to PostgreSQL.

### Complexity Assessment

- **Effort**: Very High (60-100 hours)
- **Risk**: High (significant architectural change)
- **Testing**: Business validation of reports and dashboards required

---

## 12. Sequences Migration

### Challenge Description

SQL Server sequences are directly compatible with PostgreSQL sequences with minor syntax differences.

### Affected Files

All sequences in `wwi-ssdt/wwi-ssdt/Sequences/Sequences/`:
- CustomerID.sql, OrderID.sql, InvoiceID.sql, etc. (26 total)

### SQL Server Syntax

```sql
CREATE SEQUENCE [Sequences].[CustomerID]
    AS INT
    START WITH 1110
    INCREMENT BY 1;
```

### PostgreSQL Migration

```sql
CREATE SEQUENCE sequences.customer_id
    AS INTEGER
    START WITH 1110
    INCREMENT BY 1;
```

### Complexity Assessment

- **Effort**: Low (2-4 hours)
- **Risk**: Low (direct equivalent)
- **Testing**: Minimal testing required

---

## Migration Priority Matrix

| Priority | Challenge | Effort | Risk | Dependencies |
|----------|-----------|--------|------|--------------|
| P1 | Temporal Tables | High | Medium | None |
| P1 | Memory-Optimized Tables | High | High | None |
| P1 | Stored Procedures | Very High | High | Temporal Tables |
| P1 | SSIS ETL | High | Medium | All schema objects |
| P2 | Row-Level Security | Medium | Medium | Schema migration |
| P2 | Dynamic Data Masking | Low-Medium | Low | Schema migration |
| P2 | Full-Text Search | Medium | Medium | Schema migration |
| P2 | Geography Data Type | Low-Medium | Low | PostGIS extension |
| P2 | Columnstore Indexes | Medium | Medium | Schema migration |
| P2 | Partitioning | Medium | Low | Schema migration |
| P3 | Sequences | Low | Low | None |
| P3 | JSON Functions | Low | Low | Schema migration |
| P1 | SSAS Cubes | Very High | High | DW migration complete |

---

## Estimated Total Migration Effort

| Category | Hours (Low) | Hours (High) |
|----------|-------------|--------------|
| Schema Migration | 40 | 60 |
| Temporal Tables | 40 | 60 |
| Memory-Optimized Tables | 30 | 45 |
| Stored Procedures | 100 | 150 |
| Security Features | 25 | 40 |
| Full-Text Search | 20 | 30 |
| Geography/PostGIS | 10 | 15 |
| Indexing/Partitioning | 30 | 45 |
| ETL (SSIS replacement) | 40 | 60 |
| OLAP (SSAS replacement) | 60 | 100 |
| Testing & Validation | 80 | 120 |
| **Total** | **475** | **725** |

---

## Recommended Migration Approach

1. **Phase 1: Foundation (Weeks 1-4)**
   - Set up PostgreSQL environment with extensions
   - Migrate schema (tables, sequences, constraints)
   - Implement temporal table triggers
   - Convert basic stored procedures

2. **Phase 2: Core Features (Weeks 5-8)**
   - Implement Row-Level Security
   - Set up Full-Text Search
   - Configure PostGIS for geography data
   - Convert remaining stored procedures

3. **Phase 3: Data Migration (Weeks 9-12)**
   - Migrate OLTP data
   - Validate data integrity
   - Performance tuning

4. **Phase 4: ETL & Analytics (Weeks 13-16)**
   - Replace SSIS with Airflow/dbt
   - Migrate data warehouse
   - Implement OLAP alternatives

5. **Phase 5: Testing & Cutover (Weeks 17-20)**
   - Comprehensive testing
   - Performance benchmarking
   - Parallel running
   - Production cutover
