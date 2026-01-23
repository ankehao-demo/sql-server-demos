-- Wide World Importers PostgreSQL Migration
-- Phase 6: Data Migration and Validation
-- File: 002-load-olap-data.sql
-- Description: PostgreSQL COPY commands to load OLAP (Data Warehouse) data
--
-- Prerequisites:
-- 1. PostgreSQL DW schema must be created (run postgres-migration-dw/install.sql first)
-- 2. Data must be extracted from SQL Server
-- 3. OLTP data should be loaded first if ETL will be used
--
-- Usage: Run this script against the PostgreSQL data warehouse database
-- psql -d wideworldimportersdw -f 002-load-olap-data.sql

-- =============================================
-- Pre-Load Setup
-- =============================================

-- Disable triggers during bulk load
SET session_replication_role = 'replica';

-- Set work_mem for better COPY performance
SET work_mem = '256MB';

-- =============================================
-- Integration Tables (Load First - ETL Control)
-- =============================================

\echo 'Loading Integration.Lineage...'
COPY integration.lineage (
    lineage_key, data_load_started, table_name, data_load_completed,
    was_successful, source_system_cutoff_time
) FROM :'data_dir'/olap/integration_lineage.csv
WITH (FORMAT csv, DELIMITER '|', NULL '', QUOTE '"');

\echo 'Loading Integration.ETL_Cutoff...'
COPY integration.etl_cutoff (
    table_name, cutoff_time
) FROM :'data_dir'/olap/integration_etl_cutoff.csv
WITH (FORMAT csv, DELIMITER '|', NULL '', QUOTE '"');

-- =============================================
-- Dimension Tables
-- =============================================

-- Dimension.Date (no geography, simple load)
\echo 'Loading Dimension.Date...'
COPY dimension.date (
    date, date_key, day_number, day, day_of_year, day_of_year_number,
    day_of_week, day_of_week_number, week_of_year, month, short_month,
    quarter, half_of_year, beginning_of_month, beginning_of_quarter,
    beginning_of_half_year, beginning_of_year, beginning_of_month_label,
    beginning_of_month_label_short, beginning_of_quarter_label,
    beginning_of_quarter_label_short, beginning_of_half_year_label,
    beginning_of_half_year_label_short, beginning_of_year_label,
    beginning_of_year_label_short, calendar_day_label, calendar_day_label_short,
    calendar_week_number, calendar_week_label, calendar_month_number,
    calendar_month_label, calendar_month_year_label, calendar_quarter_number,
    calendar_quarter_label, calendar_quarter_year_label,
    calendar_half_of_year_number, calendar_half_of_year_label,
    calendar_year_half_of_year_label, calendar_year, calendar_year_label,
    fiscal_month_number, fiscal_month_label, fiscal_quarter_number,
    fiscal_quarter_label, fiscal_half_of_year_number, fiscal_half_of_year_label,
    fiscal_year, fiscal_year_label, date_key_alt, year_week_key,
    year_month_key, year_quarter_key, year_half_of_year_key, year_key,
    beginning_of_month_key, beginning_of_quarter_key, beginning_of_half_year_key,
    beginning_of_year_key, fiscal_year_month_key, fiscal_year_quarter_key,
    fiscal_year_half_of_year_key, iso_week_number
) FROM :'data_dir'/olap/dimension_date.csv
WITH (FORMAT csv, DELIMITER '|', NULL '', QUOTE '"');

-- Dimension.City (has geography column)
\echo 'Loading Dimension.City...'
CREATE TEMP TABLE city_staging (
    city_key integer,
    wwi_city_id integer,
    city varchar(50),
    state_province varchar(50),
    country varchar(60),
    continent varchar(30),
    sales_territory varchar(50),
    region varchar(30),
    subregion varchar(30),
    location_wkt text,
    latest_recorded_population bigint,
    valid_from timestamp,
    valid_to timestamp,
    lineage_key integer
);

COPY city_staging FROM :'data_dir'/olap/dimension_city.csv
WITH (FORMAT csv, DELIMITER '|', NULL '', QUOTE '"');

INSERT INTO dimension.city (
    city_key, wwi_city_id, city, state_province, country, continent,
    sales_territory, region, subregion, location, latest_recorded_population,
    valid_from, valid_to, lineage_key
)
SELECT 
    city_key, wwi_city_id, city, state_province, country, continent,
    sales_territory, region, subregion,
    CASE WHEN location_wkt IS NOT NULL AND location_wkt != '' 
         THEN ST_GeogFromText(location_wkt) 
         ELSE NULL END,
    latest_recorded_population, valid_from, valid_to, lineage_key
FROM city_staging;

DROP TABLE city_staging;

-- Dimension.Customer
\echo 'Loading Dimension.Customer...'
COPY dimension.customer (
    customer_key, wwi_customer_id, customer, bill_to_customer, category,
    buying_group, primary_contact, postal_code, valid_from, valid_to, lineage_key
) FROM :'data_dir'/olap/dimension_customer.csv
WITH (FORMAT csv, DELIMITER '|', NULL '', QUOTE '"');

-- Dimension.Employee (has photo binary)
\echo 'Loading Dimension.Employee...'
COPY dimension.employee (
    employee_key, wwi_employee_id, employee, preferred_name, is_salesperson,
    photo, valid_from, valid_to, lineage_key
) FROM :'data_dir'/olap/dimension_employee.csv
WITH (FORMAT csv, DELIMITER '|', NULL '', QUOTE '"');

-- Dimension.Payment_Method
\echo 'Loading Dimension.Payment_Method...'
COPY dimension.payment_method (
    payment_method_key, wwi_payment_method_id, payment_method,
    valid_from, valid_to, lineage_key
) FROM :'data_dir'/olap/dimension_payment_method.csv
WITH (FORMAT csv, DELIMITER '|', NULL '', QUOTE '"');

-- Dimension.Stock_Item (has photo binary)
\echo 'Loading Dimension.Stock_Item...'
COPY dimension.stock_item (
    stock_item_key, wwi_stock_item_id, stock_item, color, selling_package,
    buying_package, brand, size, lead_time_days, quantity_per_outer,
    is_chiller_stock, barcode, tax_rate, unit_price, recommended_retail_price,
    typical_weight_per_unit, photo, valid_from, valid_to, lineage_key
) FROM :'data_dir'/olap/dimension_stock_item.csv
WITH (FORMAT csv, DELIMITER '|', NULL '', QUOTE '"');

-- Dimension.Supplier
\echo 'Loading Dimension.Supplier...'
COPY dimension.supplier (
    supplier_key, wwi_supplier_id, supplier, category, primary_contact,
    supplier_reference, payment_days, postal_code, valid_from, valid_to, lineage_key
) FROM :'data_dir'/olap/dimension_supplier.csv
WITH (FORMAT csv, DELIMITER '|', NULL '', QUOTE '"');

-- Dimension.Transaction_Type
\echo 'Loading Dimension.Transaction_Type...'
COPY dimension.transaction_type (
    transaction_type_key, wwi_transaction_type_id, transaction_type,
    valid_from, valid_to, lineage_key
) FROM :'data_dir'/olap/dimension_transaction_type.csv
WITH (FORMAT csv, DELIMITER '|', NULL '', QUOTE '"');

-- =============================================
-- Fact Tables
-- =============================================

-- Fact.Sale (partitioned table)
\echo 'Loading Fact.Sale...'
COPY fact.sale (
    sale_key, city_key, customer_key, bill_to_customer_key, stock_item_key,
    invoice_date_key, delivery_date_key, salesperson_key, wwi_invoice_id,
    description, package, quantity, unit_price, tax_rate, total_excluding_tax,
    tax_amount, profit, total_including_tax, total_dry_items, total_chiller_items,
    lineage_key
) FROM :'data_dir'/olap/fact_sale.csv
WITH (FORMAT csv, DELIMITER '|', NULL '', QUOTE '"');

-- Fact.Order (partitioned table)
\echo 'Loading Fact.Order...'
COPY fact.order (
    order_key, city_key, customer_key, stock_item_key, order_date_key,
    picked_date_key, salesperson_key, picker_key, wwi_order_id, wwi_backorder_id,
    description, package, quantity, unit_price, tax_rate, total_excluding_tax,
    tax_amount, total_including_tax, lineage_key
) FROM :'data_dir'/olap/fact_order.csv
WITH (FORMAT csv, DELIMITER '|', NULL '', QUOTE '"');

-- Fact.Purchase (partitioned table)
\echo 'Loading Fact.Purchase...'
COPY fact.purchase (
    purchase_key, date_key, supplier_key, stock_item_key, wwi_purchase_order_id,
    ordered_outers, ordered_quantity, received_outers, package, is_order_finalized,
    lineage_key
) FROM :'data_dir'/olap/fact_purchase.csv
WITH (FORMAT csv, DELIMITER '|', NULL '', QUOTE '"');

-- Fact.Movement (partitioned table)
\echo 'Loading Fact.Movement...'
COPY fact.movement (
    movement_key, date_key, stock_item_key, customer_key, supplier_key,
    transaction_type_key, wwi_stock_item_transaction_id, wwi_invoice_id,
    wwi_purchase_order_id, quantity, lineage_key
) FROM :'data_dir'/olap/fact_movement.csv
WITH (FORMAT csv, DELIMITER '|', NULL '', QUOTE '"');

-- Fact.Transaction (partitioned table)
\echo 'Loading Fact.Transaction...'
COPY fact.transaction (
    transaction_key, date_key, customer_key, bill_to_customer_key, supplier_key,
    transaction_type_key, payment_method_key, wwi_customer_transaction_id,
    wwi_supplier_transaction_id, wwi_invoice_id, wwi_purchase_order_id,
    supplier_invoice_number, total_excluding_tax, tax_amount, total_including_tax,
    outstanding_balance, is_finalized, lineage_key
) FROM :'data_dir'/olap/fact_transaction.csv
WITH (FORMAT csv, DELIMITER '|', NULL '', QUOTE '"');

-- Fact.Stock_Holding
\echo 'Loading Fact.Stock_Holding...'
COPY fact.stock_holding (
    stock_holding_key, stock_item_key, quantity_on_hand, bin_location,
    last_stocktake_quantity, last_cost_price, reorder_level, target_stock_level,
    lineage_key
) FROM :'data_dir'/olap/fact_stock_holding.csv
WITH (FORMAT csv, DELIMITER '|', NULL '', QUOTE '"');

-- =============================================
-- Post-Load Setup
-- =============================================

-- Re-enable triggers
SET session_replication_role = 'origin';

-- Reset work_mem
RESET work_mem;

\echo 'OLAP Data Load Complete!'
