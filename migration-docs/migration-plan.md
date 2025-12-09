# Migration Plan - Wide World Importers SQL Server to PostgreSQL

This document outlines the overall migration approach for converting the Wide World Importers database from SQL Server to PostgreSQL.

## 1. Data Type Mapping Strategy

### Numeric Types

| SQL Server Type | PostgreSQL Type | Notes |
|-----------------|-----------------|-------|
| `INT` | `INTEGER` | Direct mapping |
| `BIGINT` | `BIGINT` | Direct mapping |
| `SMALLINT` | `SMALLINT` | Direct mapping |
| `TINYINT` | `SMALLINT` | PostgreSQL has no TINYINT |
| `BIT` | `BOOLEAN` | Direct mapping |
| `DECIMAL(p,s)` | `DECIMAL(p,s)` | Direct mapping |
| `NUMERIC(p,s)` | `NUMERIC(p,s)` | Direct mapping |
| `MONEY` | `DECIMAL(19,4)` | Explicit precision |
| `SMALLMONEY` | `DECIMAL(10,4)` | Explicit precision |
| `FLOAT` | `DOUBLE PRECISION` | Direct mapping |
| `REAL` | `REAL` | Direct mapping |

### String Types

| SQL Server Type | PostgreSQL Type | Notes |
|-----------------|-----------------|-------|
| `CHAR(n)` | `CHAR(n)` | Direct mapping |
| `VARCHAR(n)` | `VARCHAR(n)` | Direct mapping |
| `VARCHAR(MAX)` | `TEXT` | Unlimited length |
| `NCHAR(n)` | `CHAR(n)` | PostgreSQL is UTF-8 by default |
| `NVARCHAR(n)` | `VARCHAR(n)` | PostgreSQL is UTF-8 by default |
| `NVARCHAR(MAX)` | `TEXT` | Unlimited length |
| `TEXT` | `TEXT` | Direct mapping |
| `NTEXT` | `TEXT` | Deprecated in SQL Server |

### Date/Time Types

| SQL Server Type | PostgreSQL Type | Notes |
|-----------------|-----------------|-------|
| `DATE` | `DATE` | Direct mapping |
| `TIME` | `TIME` | Direct mapping |
| `DATETIME` | `TIMESTAMP` | Precision to microseconds |
| `DATETIME2(n)` | `TIMESTAMP(n)` | n = 0-6 (PostgreSQL max is 6) |
| `SMALLDATETIME` | `TIMESTAMP(0)` | Minute precision |
| `DATETIMEOFFSET` | `TIMESTAMPTZ` | With timezone |

### Binary Types

| SQL Server Type | PostgreSQL Type | Notes |
|-----------------|-----------------|-------|
| `BINARY(n)` | `BYTEA` | Variable length in PostgreSQL |
| `VARBINARY(n)` | `BYTEA` | Variable length |
| `VARBINARY(MAX)` | `BYTEA` | Variable length |
| `IMAGE` | `BYTEA` | Deprecated in SQL Server |

### Special Types

| SQL Server Type | PostgreSQL Type | Notes |
|-----------------|-----------------|-------|
| `UNIQUEIDENTIFIER` | `UUID` | Direct mapping |
| `XML` | `XML` | Direct mapping |
| `GEOGRAPHY` | `GEOGRAPHY` (PostGIS) | Requires PostGIS extension |
| `GEOMETRY` | `GEOMETRY` (PostGIS) | Requires PostGIS extension |
| `HIERARCHYID` | Custom implementation | No direct equivalent |
| `SQL_VARIANT` | `JSONB` or custom | No direct equivalent |

### WWI-Specific Type Mappings

```sql
-- Application.Cities
-- SQL Server
[Location] [sys].[geography] NULL

-- PostgreSQL
location GEOGRAPHY(Point, 4326)

-- Application.People
-- SQL Server
[HashedPassword] VARBINARY(MAX) NOT NULL

-- PostgreSQL
hashed_password BYTEA NOT NULL

-- Warehouse.StockItems
-- SQL Server
[CustomFields] NVARCHAR(MAX) NULL

-- PostgreSQL
custom_fields JSONB
```

## 2. Temporal Tables Implementation

### Overview

SQL Server's temporal tables automatically track data changes. PostgreSQL requires manual implementation using triggers and history tables.

### Implementation Pattern

#### Step 1: Create Main Table with Temporal Columns

```sql
CREATE TABLE application.cities (
    city_id INTEGER PRIMARY KEY,
    city_name VARCHAR(50) NOT NULL,
    state_province_id INTEGER NOT NULL,
    location GEOGRAPHY(Point, 4326),
    latest_recorded_population BIGINT,
    last_edited_by INTEGER NOT NULL,
    valid_from TIMESTAMP NOT NULL DEFAULT clock_timestamp(),
    valid_to TIMESTAMP NOT NULL DEFAULT '9999-12-31 23:59:59.999999'::timestamp,
    
    CONSTRAINT fk_cities_state_province 
        FOREIGN KEY (state_province_id) REFERENCES application.state_provinces(state_province_id),
    CONSTRAINT fk_cities_last_edited_by 
        FOREIGN KEY (last_edited_by) REFERENCES application.people(person_id)
);
```

#### Step 2: Create History Table

```sql
CREATE TABLE application.cities_archive (
    city_id INTEGER NOT NULL,
    city_name VARCHAR(50) NOT NULL,
    state_province_id INTEGER NOT NULL,
    location GEOGRAPHY(Point, 4326),
    latest_recorded_population BIGINT,
    last_edited_by INTEGER NOT NULL,
    valid_from TIMESTAMP NOT NULL,
    valid_to TIMESTAMP NOT NULL,
    
    CONSTRAINT pk_cities_archive PRIMARY KEY (city_id, valid_from)
);

CREATE INDEX idx_cities_archive_valid_to ON application.cities_archive(valid_to);
```

#### Step 3: Create Temporal Trigger Function

```sql
CREATE OR REPLACE FUNCTION application.cities_temporal_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        -- Archive the old version
        INSERT INTO application.cities_archive 
        SELECT OLD.city_id, OLD.city_name, OLD.state_province_id, OLD.location,
               OLD.latest_recorded_population, OLD.last_edited_by,
               OLD.valid_from, clock_timestamp();
        
        -- Update valid_from on the new version
        NEW.valid_from := clock_timestamp();
        NEW.valid_to := '9999-12-31 23:59:59.999999'::timestamp;
        RETURN NEW;
        
    ELSIF TG_OP = 'DELETE' THEN
        -- Archive the deleted version
        INSERT INTO application.cities_archive 
        SELECT OLD.city_id, OLD.city_name, OLD.state_province_id, OLD.location,
               OLD.latest_recorded_population, OLD.last_edited_by,
               OLD.valid_from, clock_timestamp();
        RETURN OLD;
    END IF;
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER cities_temporal
BEFORE UPDATE OR DELETE ON application.cities
FOR EACH ROW EXECUTE FUNCTION application.cities_temporal_trigger();
```

#### Step 4: Create Temporal Query Functions

```sql
-- Query data as of a specific point in time
CREATE OR REPLACE FUNCTION application.cities_as_of(as_of_time TIMESTAMP)
RETURNS TABLE (
    city_id INTEGER,
    city_name VARCHAR(50),
    state_province_id INTEGER,
    location GEOGRAPHY,
    latest_recorded_population BIGINT,
    last_edited_by INTEGER,
    valid_from TIMESTAMP,
    valid_to TIMESTAMP
) AS $$
BEGIN
    RETURN QUERY
    SELECT c.city_id, c.city_name, c.state_province_id, c.location,
           c.latest_recorded_population, c.last_edited_by, c.valid_from, c.valid_to
    FROM application.cities c
    WHERE c.valid_from <= as_of_time AND c.valid_to > as_of_time
    UNION ALL
    SELECT a.city_id, a.city_name, a.state_province_id, a.location,
           a.latest_recorded_population, a.last_edited_by, a.valid_from, a.valid_to
    FROM application.cities_archive a
    WHERE a.valid_from <= as_of_time AND a.valid_to > as_of_time;
END;
$$ LANGUAGE plpgsql;

-- Query data changes between two points in time
CREATE OR REPLACE FUNCTION application.cities_between(start_time TIMESTAMP, end_time TIMESTAMP)
RETURNS TABLE (
    city_id INTEGER,
    city_name VARCHAR(50),
    state_province_id INTEGER,
    location GEOGRAPHY,
    latest_recorded_population BIGINT,
    last_edited_by INTEGER,
    valid_from TIMESTAMP,
    valid_to TIMESTAMP
) AS $$
BEGIN
    RETURN QUERY
    SELECT c.city_id, c.city_name, c.state_province_id, c.location,
           c.latest_recorded_population, c.last_edited_by, c.valid_from, c.valid_to
    FROM application.cities c
    WHERE c.valid_from <= end_time AND c.valid_to > start_time
    UNION ALL
    SELECT a.city_id, a.city_name, a.state_province_id, a.location,
           a.latest_recorded_population, a.last_edited_by, a.valid_from, a.valid_to
    FROM application.cities_archive a
    WHERE a.valid_from <= end_time AND a.valid_to > start_time;
END;
$$ LANGUAGE plpgsql;
```

### Temporal Tables to Implement

| Main Table | History Table | Priority |
|------------|---------------|----------|
| application.cities | application.cities_archive | High |
| application.countries | application.countries_archive | High |
| application.people | application.people_archive | High |
| application.state_provinces | application.state_provinces_archive | High |
| sales.customers | sales.customers_archive | High |
| warehouse.stock_items | warehouse.stock_items_archive | High |
| purchasing.suppliers | purchasing.suppliers_archive | High |
| application.delivery_methods | application.delivery_methods_archive | Medium |
| application.payment_methods | application.payment_methods_archive | Medium |
| application.transaction_types | application.transaction_types_archive | Medium |
| sales.buying_groups | sales.buying_groups_archive | Medium |
| sales.customer_categories | sales.customer_categories_archive | Medium |
| warehouse.colors | warehouse.colors_archive | Low |
| warehouse.package_types | warehouse.package_types_archive | Low |
| warehouse.stock_groups | warehouse.stock_groups_archive | Low |
| purchasing.supplier_categories | purchasing.supplier_categories_archive | Low |
| warehouse.cold_room_temperatures | warehouse.cold_room_temperatures_archive | Low |

## 3. Memory-Optimized Tables Strategy

### Challenge

SQL Server's In-Memory OLTP provides memory-optimized tables for high-performance scenarios. PostgreSQL does not have an equivalent feature.

### Affected Tables

1. **Warehouse.ColdRoomTemperatures** - High-frequency sensor data
2. **Warehouse.VehicleTemperatures** - Vehicle sensor data

### Migration Strategy

#### Option 1: Standard PostgreSQL Tables (Recommended)

Convert to regular PostgreSQL tables with optimizations:

```sql
CREATE TABLE warehouse.cold_room_temperatures (
    cold_room_temperature_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    cold_room_sensor_number INTEGER NOT NULL,
    recorded_when TIMESTAMP NOT NULL,
    temperature DECIMAL(10,2) NOT NULL,
    valid_from TIMESTAMP NOT NULL DEFAULT clock_timestamp(),
    valid_to TIMESTAMP NOT NULL DEFAULT '9999-12-31 23:59:59.999999'::timestamp
);

-- Optimize for high-frequency inserts
CREATE INDEX idx_cold_room_temps_sensor ON warehouse.cold_room_temperatures(cold_room_sensor_number);
CREATE INDEX idx_cold_room_temps_when ON warehouse.cold_room_temperatures(recorded_when);

-- Consider BRIN index for time-series data
CREATE INDEX idx_cold_room_temps_when_brin ON warehouse.cold_room_temperatures 
USING BRIN(recorded_when) WITH (pages_per_range = 128);
```

#### Option 2: UNLOGGED Tables (High Performance, No Durability)

For non-critical sensor data where performance is paramount:

```sql
CREATE UNLOGGED TABLE warehouse.vehicle_temperatures (
    vehicle_temperature_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    vehicle_registration VARCHAR(20) NOT NULL,
    chiller_sensor_number INTEGER NOT NULL,
    recorded_when TIMESTAMP NOT NULL,
    temperature DECIMAL(10,2) NOT NULL,
    full_sensor_data VARCHAR(1000),
    is_compressed BOOLEAN NOT NULL DEFAULT false,
    compressed_sensor_data BYTEA
);
```

**Warning:** UNLOGGED tables are not crash-safe. Data may be lost on server crash.

#### Option 3: TimescaleDB Extension (Time-Series Optimized)

For production deployments with high-volume sensor data:

```sql
-- Install TimescaleDB extension
CREATE EXTENSION IF NOT EXISTS timescaledb;

-- Create hypertable
CREATE TABLE warehouse.cold_room_temperatures (
    cold_room_temperature_id BIGINT GENERATED ALWAYS AS IDENTITY,
    cold_room_sensor_number INTEGER NOT NULL,
    recorded_when TIMESTAMPTZ NOT NULL,
    temperature DECIMAL(10,2) NOT NULL
);

SELECT create_hypertable('warehouse.cold_room_temperatures', 'recorded_when');
```

### Memory-Optimized TVPs Replacement

SQL Server memory-optimized table-valued parameters need replacement:

```sql
-- SQL Server
CREATE TYPE [Website].[OrderIDList] AS TABLE (
    [OrderID] INT NOT NULL PRIMARY KEY NONCLUSTERED
) WITH (MEMORY_OPTIMIZED = ON);

-- PostgreSQL Option 1: Regular table type (for function parameters)
CREATE TYPE website.order_id_list AS (order_id INTEGER);

-- PostgreSQL Option 2: Temporary tables
CREATE TEMP TABLE temp_order_ids (order_id INTEGER PRIMARY KEY);

-- PostgreSQL Option 3: Arrays
CREATE OR REPLACE FUNCTION website.process_orders(order_ids INTEGER[])
RETURNS void AS $$
BEGIN
    -- Process orders using unnest(order_ids)
END;
$$ LANGUAGE plpgsql;
```

## 4. ETL Replacement Strategy (SSIS Packages)

### Current SSIS Workflow

The Daily ETL package performs:
1. Calculate cutoff time
2. Populate Date dimension
3. Load dimension tables (City, Customer, Employee, etc.)
4. Load fact tables (Sale, Order, Purchase, Movement, Transaction, Stock Holding)

### PostgreSQL ETL Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    ETL Orchestration                         │
│                                                              │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐  │
│  │   pg_cron    │    │   Airflow    │    │    dbt       │  │
│  │  (Simple)    │    │  (Complex)   │    │(Transforms)  │  │
│  └──────────────┘    └──────────────┘    └──────────────┘  │
│         │                   │                   │           │
│         └───────────────────┴───────────────────┘           │
│                            │                                 │
│                    ┌───────▼───────┐                        │
│                    │  PL/pgSQL     │                        │
│                    │  Procedures   │                        │
│                    └───────────────┘                        │
└─────────────────────────────────────────────────────────────┘
```

### Option 1: pg_cron + PL/pgSQL (Recommended for Simplicity)

```sql
-- Create ETL orchestration procedure
CREATE OR REPLACE PROCEDURE integration.run_daily_etl()
LANGUAGE plpgsql
AS $$
DECLARE
    v_cutoff_time TIMESTAMP;
    v_start_time TIMESTAMP := clock_timestamp();
BEGIN
    -- Calculate cutoff time (current time minus buffer)
    v_cutoff_time := clock_timestamp() - INTERVAL '10 seconds';
    
    -- Log ETL start
    INSERT INTO integration.etl_log (etl_name, start_time, status)
    VALUES ('Daily ETL', v_start_time, 'Running');
    
    -- Step 1: Populate Date dimension
    CALL integration.populate_date_dimension();
    
    -- Step 2: Load dimensions
    CALL integration.load_city_dimension(v_cutoff_time);
    CALL integration.load_customer_dimension(v_cutoff_time);
    CALL integration.load_employee_dimension(v_cutoff_time);
    CALL integration.load_payment_method_dimension(v_cutoff_time);
    CALL integration.load_stock_item_dimension(v_cutoff_time);
    CALL integration.load_supplier_dimension(v_cutoff_time);
    CALL integration.load_transaction_type_dimension(v_cutoff_time);
    
    -- Step 3: Load facts
    CALL integration.load_sale_fact(v_cutoff_time);
    CALL integration.load_order_fact(v_cutoff_time);
    CALL integration.load_purchase_fact(v_cutoff_time);
    CALL integration.load_movement_fact(v_cutoff_time);
    CALL integration.load_transaction_fact(v_cutoff_time);
    CALL integration.load_stock_holding_fact(v_cutoff_time);
    
    -- Log ETL completion
    UPDATE integration.etl_log 
    SET end_time = clock_timestamp(), status = 'Completed'
    WHERE etl_name = 'Daily ETL' AND start_time = v_start_time;
    
EXCEPTION WHEN OTHERS THEN
    -- Log error
    UPDATE integration.etl_log 
    SET end_time = clock_timestamp(), status = 'Failed', error_message = SQLERRM
    WHERE etl_name = 'Daily ETL' AND start_time = v_start_time;
    RAISE;
END;
$$;

-- Schedule with pg_cron (daily at 2 AM)
SELECT cron.schedule('daily-etl', '0 2 * * *', 'CALL integration.run_daily_etl()');
```

### Option 2: Apache Airflow (Recommended for Complex Workflows)

```python
# dags/wwi_daily_etl.py
from airflow import DAG
from airflow.providers.postgres.operators.postgres import PostgresOperator
from datetime import datetime, timedelta

default_args = {
    'owner': 'wwi',
    'depends_on_past': False,
    'start_date': datetime(2025, 1, 1),
    'retries': 3,
    'retry_delay': timedelta(minutes=5),
}

dag = DAG(
    'wwi_daily_etl',
    default_args=default_args,
    description='Wide World Importers Daily ETL',
    schedule_interval='0 2 * * *',
    catchup=False,
)

# Dimension loading tasks
load_city = PostgresOperator(
    task_id='load_city_dimension',
    postgres_conn_id='wwi_postgres',
    sql='CALL integration.load_city_dimension(%(cutoff_time)s)',
    parameters={'cutoff_time': '{{ ts }}'},
    dag=dag,
)

load_customer = PostgresOperator(
    task_id='load_customer_dimension',
    postgres_conn_id='wwi_postgres',
    sql='CALL integration.load_customer_dimension(%(cutoff_time)s)',
    parameters={'cutoff_time': '{{ ts }}'},
    dag=dag,
)

# Fact loading tasks
load_sale = PostgresOperator(
    task_id='load_sale_fact',
    postgres_conn_id='wwi_postgres',
    sql='CALL integration.load_sale_fact(%(cutoff_time)s)',
    parameters={'cutoff_time': '{{ ts }}'},
    dag=dag,
)

# Define dependencies
[load_city, load_customer] >> load_sale
```

### ETL Procedure Example

```sql
-- Example: Load Customer Dimension
CREATE OR REPLACE PROCEDURE integration.load_customer_dimension(p_cutoff_time TIMESTAMP)
LANGUAGE plpgsql
AS $$
DECLARE
    v_lineage_key INTEGER;
BEGIN
    -- Get or create lineage key
    INSERT INTO integration.lineage (data_load_started, source_system)
    VALUES (clock_timestamp(), 'OLTP')
    RETURNING lineage_key INTO v_lineage_key;
    
    -- Insert new/changed customers using temporal query
    INSERT INTO dimension.customer (
        wwi_customer_id, customer, bill_to_customer, category,
        buying_group, primary_contact, postal_code,
        valid_from, valid_to, lineage_key
    )
    SELECT 
        c.customer_id,
        c.customer_name,
        bt.customer_name,
        cc.customer_category_name,
        COALESCE(bg.buying_group_name, 'N/A'),
        p.full_name,
        c.postal_postal_code,
        c.valid_from,
        c.valid_to,
        v_lineage_key
    FROM sales.customers c
    JOIN sales.customers bt ON c.bill_to_customer_id = bt.customer_id
    JOIN sales.customer_categories cc ON c.customer_category_id = cc.customer_category_id
    LEFT JOIN sales.buying_groups bg ON c.buying_group_id = bg.buying_group_id
    JOIN application.people p ON c.primary_contact_person_id = p.person_id
    WHERE c.valid_from <= p_cutoff_time
    ON CONFLICT (wwi_customer_id, valid_from) 
    DO UPDATE SET
        customer = EXCLUDED.customer,
        bill_to_customer = EXCLUDED.bill_to_customer,
        category = EXCLUDED.category,
        buying_group = EXCLUDED.buying_group,
        primary_contact = EXCLUDED.primary_contact,
        postal_code = EXCLUDED.postal_code,
        valid_to = EXCLUDED.valid_to,
        lineage_key = EXCLUDED.lineage_key;
    
    -- Update lineage record
    UPDATE integration.lineage 
    SET data_load_completed = clock_timestamp(),
        rows_processed = (SELECT COUNT(*) FROM dimension.customer WHERE lineage_key = v_lineage_key)
    WHERE lineage_key = v_lineage_key;
END;
$$;
```

## 5. Stored Procedure Conversion

### Function Mapping

| SQL Server | PostgreSQL | Notes |
|------------|------------|-------|
| `CREATE PROCEDURE` | `CREATE PROCEDURE` (PG11+) | Use for side effects |
| `CREATE FUNCTION` | `CREATE FUNCTION` | Use for return values |
| `EXEC procedure` | `CALL procedure` | Different syntax |
| `SET NOCOUNT ON` | Not needed | PostgreSQL doesn't count by default |
| `BEGIN TRY/CATCH` | `BEGIN/EXCEPTION` | Different syntax |
| `RAISERROR` | `RAISE EXCEPTION` | Different syntax |
| `PRINT` | `RAISE NOTICE` | Debug output |

### Conversion Example

**SQL Server:**
```sql
CREATE PROCEDURE [Website].[ActivateWebsiteLogon]
@PersonID int,
@LogonName nvarchar(50),
@InitialPassword nvarchar(40)
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    UPDATE [Application].[People]
    SET IsPermittedToLogon = 1,
        LogonName = @LogonName,
        HashedPassword = HASHBYTES(N'SHA2_256', @InitialPassword),
        UserPreferences = (SELECT UserPreferences FROM [Application].[People] WHERE PersonID = 1)
    WHERE PersonID = @PersonID;

    IF @@ROWCOUNT = 0
    BEGIN
        PRINT N'Invalid PersonID';
        THROW 51000, N'Invalid PersonID', 1;
    END;
END;
```

**PostgreSQL:**
```sql
CREATE OR REPLACE PROCEDURE website.activate_website_logon(
    p_person_id INTEGER,
    p_logon_name VARCHAR(50),
    p_initial_password VARCHAR(40)
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_rows_affected INTEGER;
BEGIN
    UPDATE application.people
    SET is_permitted_to_logon = true,
        logon_name = p_logon_name,
        hashed_password = digest(p_initial_password, 'sha256'),
        user_preferences = (SELECT user_preferences FROM application.people WHERE person_id = 1)
    WHERE person_id = p_person_id;
    
    GET DIAGNOSTICS v_rows_affected = ROW_COUNT;
    
    IF v_rows_affected = 0 THEN
        RAISE NOTICE 'Invalid PersonID';
        RAISE EXCEPTION 'Invalid PersonID' USING ERRCODE = '51000';
    END IF;
END;
$$;
```

## 6. Security Migration

### Row-Level Security

**SQL Server:**
```sql
CREATE SECURITY POLICY [Application].FilterCustomersBySalesTerritoryRole
ADD FILTER PREDICATE [Application].DetermineCustomerAccess(DeliveryCityID)
ON Sales.Customers;
```

**PostgreSQL:**
```sql
-- Enable RLS
ALTER TABLE sales.customers ENABLE ROW LEVEL SECURITY;

-- Create policy
CREATE POLICY customer_territory_access ON sales.customers
FOR ALL
USING (
    -- db_owner has full access
    pg_has_role(current_user, 'wwi_admin', 'MEMBER')
    OR
    -- Territory-based access
    EXISTS (
        SELECT 1 
        FROM application.cities c
        JOIN application.state_provinces sp ON c.state_province_id = sp.state_province_id
        WHERE c.city_id = sales.customers.delivery_city_id
        AND pg_has_role(current_user, sp.sales_territory || ' Sales', 'MEMBER')
    )
    OR
    -- Website user with session context
    (
        session_user = 'webapi'
        AND EXISTS (
            SELECT 1 
            FROM application.cities c
            JOIN application.state_provinces sp ON c.state_province_id = sp.state_province_id
            WHERE c.city_id = sales.customers.delivery_city_id
            AND sp.sales_territory = current_setting('app.sales_territory', true)
        )
    )
);
```

## 7. Migration Phases

### Phase 1: Schema Migration (Weeks 1-2)

1. Create PostgreSQL database and schemas
2. Create sequences
3. Create tables without foreign keys
4. Create indexes
5. Add foreign key constraints

### Phase 2: Temporal Infrastructure (Weeks 3-4)

1. Create history tables
2. Create temporal trigger functions
3. Create temporal query functions
4. Test temporal functionality

### Phase 3: Stored Procedures (Weeks 5-7)

1. Convert Application schema procedures
2. Convert Website schema procedures
3. Convert DataLoadSimulation procedures
4. Convert Integration procedures

### Phase 4: Security (Week 8)

1. Create roles
2. Create users
3. Implement RLS policies
4. Test security

### Phase 5: ETL (Weeks 9-11)

1. Create ETL procedures
2. Set up scheduling (pg_cron or Airflow)
3. Test ETL workflow
4. Validate data consistency

### Phase 6: Data Migration (Weeks 12-14)

1. Initial bulk data load
2. Validate data integrity
3. Set up incremental sync (if needed)
4. Final cutover

### Phase 7: Testing and Optimization (Weeks 15-16)

1. Performance testing
2. Query optimization
3. Index tuning
4. Load testing

## 8. Data Migration Strategy

### Option 1: pg_dump/pg_restore (Small Databases)

For databases under 10GB:

```bash
# Export from SQL Server using bcp
bcp "SELECT * FROM Sales.Customers" queryout customers.csv -S localhost -d WideWorldImporters -T -c -t","

# Import to PostgreSQL
\copy sales.customers FROM 'customers.csv' WITH (FORMAT csv, HEADER true)
```

### Option 2: Foreign Data Wrapper (Live Migration)

```sql
-- Install tds_fdw extension
CREATE EXTENSION tds_fdw;

-- Create foreign server
CREATE SERVER sqlserver_wwi
FOREIGN DATA WRAPPER tds_fdw
OPTIONS (servername 'sqlserver-host', port '1433', database 'WideWorldImporters');

-- Create user mapping
CREATE USER MAPPING FOR postgres
SERVER sqlserver_wwi
OPTIONS (username 'sa', password 'password');

-- Import foreign schema
IMPORT FOREIGN SCHEMA dbo
FROM SERVER sqlserver_wwi
INTO staging;

-- Copy data
INSERT INTO sales.customers
SELECT * FROM staging.customers;
```

### Option 3: ETL Tool (Large Databases)

For databases over 100GB, use dedicated ETL tools:
- **AWS DMS** (Database Migration Service)
- **Azure Database Migration Service**
- **Striim**
- **Attunity Replicate**

## 9. Validation Checklist

### Schema Validation

- [ ] All tables created with correct columns
- [ ] All data types mapped correctly
- [ ] All primary keys created
- [ ] All foreign keys created
- [ ] All indexes created
- [ ] All sequences created

### Data Validation

- [ ] Row counts match between source and target
- [ ] Sample data spot checks pass
- [ ] Referential integrity maintained
- [ ] NULL values handled correctly
- [ ] Date/time values converted correctly

### Functionality Validation

- [ ] All stored procedures converted and tested
- [ ] Temporal queries return correct results
- [ ] RLS policies enforce correct access
- [ ] Full-text search returns expected results
- [ ] ETL processes complete successfully

### Performance Validation

- [ ] Query response times acceptable
- [ ] Bulk insert performance acceptable
- [ ] Concurrent user load handled
- [ ] Index usage optimal

## 10. Rollback Plan

### Pre-Migration

1. Full backup of SQL Server database
2. Document current state
3. Test restore procedure

### During Migration

1. Keep SQL Server database online
2. Maintain sync if possible
3. Document all changes

### Post-Migration Rollback

1. Stop PostgreSQL applications
2. Restore SQL Server from backup
3. Point applications back to SQL Server
4. Investigate and fix issues
5. Retry migration

## Appendix: Quick Reference

### Common SQL Server to PostgreSQL Conversions

```sql
-- GETDATE() -> clock_timestamp() or now()
-- SYSDATETIME() -> clock_timestamp()
-- NEWID() -> gen_random_uuid()
-- ISNULL(a, b) -> COALESCE(a, b)
-- CONVERT(type, value) -> CAST(value AS type) or value::type
-- DATEADD(day, 1, date) -> date + INTERVAL '1 day'
-- DATEDIFF(day, date1, date2) -> date2 - date1
-- TOP n -> LIMIT n
-- WITH (NOLOCK) -> (remove, use appropriate isolation level)
-- @@ROWCOUNT -> GET DIAGNOSTICS var = ROW_COUNT
-- @@IDENTITY -> lastval() or RETURNING clause
-- SCOPE_IDENTITY() -> lastval() or RETURNING clause
```
