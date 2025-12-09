# ETL Process Replacement Guide

This document provides guidance on replacing SQL Server Integration Services (SSIS) packages with PostgreSQL-compatible ETL solutions for the Wide World Importers data warehouse.

## Overview

The original Wide World Importers project uses SSIS packages in the `wwi-ssis/` directory to perform ETL operations from the OLTP database (WideWorldImporters) to the OLAP data warehouse (WideWorldImportersDW). These packages need to be replaced with PostgreSQL-compatible alternatives.

## Original SSIS Package Structure

The SSIS packages perform the following operations:
1. Load dimension tables first (City, Customer, Date, Employee, Payment Method, Stock Item, Supplier, Transaction Type)
2. Load fact tables after dimensions (Movement, Order, Purchase, Sale, Stock Holding, Transaction)
3. Use bulk T-SQL operations for data loading
4. Implement incremental loading based on ETL cutoff times

## PostgreSQL ETL Alternatives

### Option 1: Apache Airflow (Recommended)

Apache Airflow is a platform for programmatically authoring, scheduling, and monitoring workflows.

**Advantages:**
- Open-source and widely adopted
- Python-based, easy to customize
- Built-in scheduling and monitoring
- Supports PostgreSQL natively

**Implementation:**

```python
# Example Airflow DAG for WWI ETL
from airflow import DAG
from airflow.providers.postgres.operators.postgres import PostgresOperator
from airflow.operators.python import PythonOperator
from datetime import datetime, timedelta

default_args = {
    'owner': 'wwi_etl',
    'depends_on_past': False,
    'start_date': datetime(2024, 1, 1),
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

dag = DAG(
    'wwi_etl_daily',
    default_args=default_args,
    description='Wide World Importers Daily ETL',
    schedule_interval='0 2 * * *',  # Run at 2 AM daily
    catchup=False,
)

# Load dimension tables
load_dim_city = PostgresOperator(
    task_id='load_dim_city',
    postgres_conn_id='wwi_dw',
    sql='sql/load_dim_city.sql',
    dag=dag,
)

load_dim_customer = PostgresOperator(
    task_id='load_dim_customer',
    postgres_conn_id='wwi_dw',
    sql='sql/load_dim_customer.sql',
    dag=dag,
)

load_dim_date = PostgresOperator(
    task_id='load_dim_date',
    postgres_conn_id='wwi_dw',
    sql='sql/load_dim_date.sql',
    dag=dag,
)

load_dim_employee = PostgresOperator(
    task_id='load_dim_employee',
    postgres_conn_id='wwi_dw',
    sql='sql/load_dim_employee.sql',
    dag=dag,
)

load_dim_stock_item = PostgresOperator(
    task_id='load_dim_stock_item',
    postgres_conn_id='wwi_dw',
    sql='sql/load_dim_stock_item.sql',
    dag=dag,
)

load_dim_supplier = PostgresOperator(
    task_id='load_dim_supplier',
    postgres_conn_id='wwi_dw',
    sql='sql/load_dim_supplier.sql',
    dag=dag,
)

# Load fact tables (depend on dimensions)
load_fact_sale = PostgresOperator(
    task_id='load_fact_sale',
    postgres_conn_id='wwi_dw',
    sql='sql/load_fact_sale.sql',
    dag=dag,
)

load_fact_order = PostgresOperator(
    task_id='load_fact_order',
    postgres_conn_id='wwi_dw',
    sql='sql/load_fact_order.sql',
    dag=dag,
)

load_fact_purchase = PostgresOperator(
    task_id='load_fact_purchase',
    postgres_conn_id='wwi_dw',
    sql='sql/load_fact_purchase.sql',
    dag=dag,
)

load_fact_movement = PostgresOperator(
    task_id='load_fact_movement',
    postgres_conn_id='wwi_dw',
    sql='sql/load_fact_movement.sql',
    dag=dag,
)

# Define task dependencies
[load_dim_city, load_dim_customer, load_dim_date, load_dim_employee, 
 load_dim_stock_item, load_dim_supplier] >> load_fact_sale
[load_dim_city, load_dim_customer, load_dim_date, load_dim_employee, 
 load_dim_stock_item, load_dim_supplier] >> load_fact_order
[load_dim_city, load_dim_date, load_dim_stock_item, 
 load_dim_supplier] >> load_fact_purchase
[load_dim_date, load_dim_stock_item] >> load_fact_movement
```

### Option 2: dbt (Data Build Tool)

dbt is a transformation tool that enables data analysts and engineers to transform data in their warehouse.

**Advantages:**
- SQL-based transformations
- Version control friendly
- Built-in testing and documentation
- Supports incremental models

**Implementation:**

```yaml
# dbt_project.yml
name: 'wwi_dw'
version: '1.0.0'
config-version: 2

profile: 'wwi_dw'

model-paths: ["models"]
analysis-paths: ["analyses"]
test-paths: ["tests"]
seed-paths: ["seeds"]
macro-paths: ["macros"]
snapshot-paths: ["snapshots"]

target-path: "target"
clean-targets:
  - "target"
  - "dbt_packages"
```

```sql
-- models/dimensions/dim_customer.sql
{{ config(materialized='incremental', unique_key='customer_key') }}

WITH source_customers AS (
    SELECT 
        c.customerid,
        c.customername,
        c.billtocustomerid,
        cc.customercategoryname,
        bg.buyinggroupname,
        p.fullname AS primarycontact,
        ct.cityname,
        sp.stateprovincename,
        co.countryname,
        c.validfrom,
        c.validto
    FROM {{ source('wwi_oltp', 'customers') }} c
    LEFT JOIN {{ source('wwi_oltp', 'customercategories') }} cc 
        ON c.customercategoryid = cc.customercategoryid
    LEFT JOIN {{ source('wwi_oltp', 'buyinggroups') }} bg 
        ON c.buyinggroupid = bg.buyinggroupid
    LEFT JOIN {{ source('wwi_oltp', 'people') }} p 
        ON c.primarycontactpersonid = p.personid
    LEFT JOIN {{ source('wwi_oltp', 'cities') }} ct 
        ON c.deliverycityid = ct.cityid
    LEFT JOIN {{ source('wwi_oltp', 'stateprovinces') }} sp 
        ON ct.stateprovinceid = sp.stateprovinceid
    LEFT JOIN {{ source('wwi_oltp', 'countries') }} co 
        ON sp.countryid = co.countryid
    {% if is_incremental() %}
    WHERE c.validfrom > (SELECT MAX(validfrom) FROM {{ this }})
    {% endif %}
)

SELECT
    {{ dbt_utils.surrogate_key(['customerid', 'validfrom']) }} AS customer_key,
    customerid AS wwi_customer_id,
    customername AS customer,
    billtocustomerid AS bill_to_customer_id,
    customercategoryname AS category,
    buyinggroupname AS buying_group,
    primarycontact AS primary_contact,
    cityname AS city,
    stateprovincename AS state_province,
    countryname AS country,
    validfrom,
    validto
FROM source_customers
```

### Option 3: PostgreSQL Native (pg_cron + Functions)

For simpler ETL requirements, PostgreSQL's native capabilities with pg_cron extension can be used.

**Advantages:**
- No external dependencies
- Simple to set up
- Uses familiar SQL/PL/pgSQL

**Implementation:**

```sql
-- Install pg_cron extension
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Create ETL control table
CREATE TABLE IF NOT EXISTS integration.etl_cutoff (
    etl_cutoff_id serial PRIMARY KEY,
    table_name varchar(100) NOT NULL,
    cutoff_time timestamp NOT NULL,
    data_load_started timestamp,
    data_load_completed timestamp,
    rows_loaded bigint
);

-- Create dimension loading function
CREATE OR REPLACE FUNCTION integration.load_dim_customer()
RETURNS void AS $$
DECLARE
    v_cutoff_time timestamp;
    v_rows_loaded bigint;
BEGIN
    -- Get last cutoff time
    SELECT COALESCE(MAX(cutoff_time), '1900-01-01'::timestamp)
    INTO v_cutoff_time
    FROM integration.etl_cutoff
    WHERE table_name = 'dim_customer';
    
    -- Insert new/changed customers
    INSERT INTO dimension.customer (
        wwi_customer_id, customer, bill_to_customer_id, category,
        buying_group, primary_contact, city, state_province, country,
        valid_from, valid_to
    )
    SELECT 
        c.customerid,
        c.customername,
        c.billtocustomerid,
        cc.customercategoryname,
        bg.buyinggroupname,
        p.fullname,
        ct.cityname,
        sp.stateprovincename,
        co.countryname,
        c.validfrom,
        c.validto
    FROM sales.customers c
    LEFT JOIN sales.customercategories cc ON c.customercategoryid = cc.customercategoryid
    LEFT JOIN sales.buyinggroups bg ON c.buyinggroupid = bg.buyinggroupid
    LEFT JOIN application.people p ON c.primarycontactpersonid = p.personid
    LEFT JOIN application.cities ct ON c.deliverycityid = ct.cityid
    LEFT JOIN application.stateprovinces sp ON ct.stateprovinceid = sp.stateprovinceid
    LEFT JOIN application.countries co ON sp.countryid = co.countryid
    WHERE c.validfrom > v_cutoff_time
    ON CONFLICT (wwi_customer_id, valid_from) 
    DO UPDATE SET
        customer = EXCLUDED.customer,
        bill_to_customer_id = EXCLUDED.bill_to_customer_id,
        category = EXCLUDED.category,
        buying_group = EXCLUDED.buying_group,
        primary_contact = EXCLUDED.primary_contact,
        city = EXCLUDED.city,
        state_province = EXCLUDED.state_province,
        country = EXCLUDED.country,
        valid_to = EXCLUDED.valid_to;
    
    GET DIAGNOSTICS v_rows_loaded = ROW_COUNT;
    
    -- Record ETL completion
    INSERT INTO integration.etl_cutoff (table_name, cutoff_time, data_load_completed, rows_loaded)
    VALUES ('dim_customer', NOW(), NOW(), v_rows_loaded);
END;
$$ LANGUAGE plpgsql;

-- Schedule ETL job with pg_cron
SELECT cron.schedule('wwi_etl_daily', '0 2 * * *', $$
    SELECT integration.load_dim_customer();
    SELECT integration.load_dim_city();
    SELECT integration.load_dim_date();
    SELECT integration.load_dim_employee();
    SELECT integration.load_dim_stock_item();
    SELECT integration.load_dim_supplier();
    SELECT integration.load_fact_sale();
    SELECT integration.load_fact_order();
    SELECT integration.load_fact_purchase();
    SELECT integration.load_fact_movement();
$$);
```

## Analysis Services Replacement

SQL Server Analysis Services (SSAS) cubes in `wwi-ssasmd/` need to be replaced with PostgreSQL-compatible analytics solutions.

### Option 1: Apache Superset

Apache Superset is a modern data exploration and visualization platform.

**Features:**
- Interactive dashboards
- SQL-based queries
- Native PostgreSQL support
- OLAP-style slice and dice

### Option 2: Metabase

Metabase is an open-source business intelligence tool.

**Features:**
- Easy to set up
- Native PostgreSQL support
- Automatic schema discovery
- Embedded analytics

### Option 3: PostgreSQL Materialized Views

For simpler analytics requirements, PostgreSQL materialized views can provide pre-aggregated data.

```sql
-- Create materialized view for sales summary
CREATE MATERIALIZED VIEW analytics.sales_summary AS
SELECT 
    d.calendar_year,
    d.calendar_month,
    c.customername,
    si.stockitemname,
    SUM(f.quantity) AS total_quantity,
    SUM(f.total_including_tax) AS total_sales,
    SUM(f.profit) AS total_profit
FROM fact.sale f
JOIN dimension.date d ON f.invoice_date_key = d.date_key
JOIN dimension.customer c ON f.customer_key = c.customer_key
JOIN dimension.stock_item si ON f.stock_item_key = si.stock_item_key
GROUP BY d.calendar_year, d.calendar_month, c.customername, si.stockitemname;

-- Create index for fast queries
CREATE INDEX idx_sales_summary_year_month ON analytics.sales_summary(calendar_year, calendar_month);

-- Refresh materialized view (can be scheduled with pg_cron)
REFRESH MATERIALIZED VIEW CONCURRENTLY analytics.sales_summary;
```

## Migration Checklist

1. [ ] Choose ETL tool (Airflow, dbt, or native PostgreSQL)
2. [ ] Set up data warehouse schema in PostgreSQL
3. [ ] Create dimension loading procedures/models
4. [ ] Create fact loading procedures/models
5. [ ] Set up scheduling (Airflow scheduler, dbt Cloud, or pg_cron)
6. [ ] Implement monitoring and alerting
7. [ ] Choose analytics tool (Superset, Metabase, or custom)
8. [ ] Create dashboards and reports
9. [ ] Test ETL processes with sample data
10. [ ] Validate data accuracy against source
11. [ ] Document ETL processes and schedules
12. [ ] Set up backup and recovery procedures
