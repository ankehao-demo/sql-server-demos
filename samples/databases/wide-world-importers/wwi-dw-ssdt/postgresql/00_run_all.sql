-- Wide World Importers Data Warehouse - PostgreSQL Schema Migration
-- Phase 4: OLAP Schema Migration
-- Master script to run all migration scripts in the correct order

-- Prerequisites: Ensure PostGIS extension is available
CREATE EXTENSION IF NOT EXISTS postgis;

\echo '=== Phase 4: OLAP Schema Migration ==='
\echo ''

-- Step 1: Create schemas
\echo 'Step 1: Creating schemas...'
\i schemas/00_create_schemas.sql
\echo 'Schemas created successfully.'
\echo ''

-- Step 2: Create sequences
\echo 'Step 2: Creating sequences...'
\i sequences/01_create_sequences.sql
\echo 'Sequences created successfully.'
\echo ''

-- Step 3: Create dimension tables
\echo 'Step 3: Creating dimension tables...'
\i dimension/02_dimension_date.sql
\i dimension/02_dimension_city.sql
\i dimension/02_dimension_customer.sql
\i dimension/02_dimension_employee.sql
\i dimension/02_dimension_payment_method.sql
\i dimension/02_dimension_stock_item.sql
\i dimension/02_dimension_supplier.sql
\i dimension/02_dimension_transaction_type.sql
\echo 'Dimension tables created successfully.'
\echo ''

-- Step 4: Create fact tables (with partitioning)
\echo 'Step 4: Creating fact tables...'
\i fact/03_fact_sale.sql
\i fact/03_fact_order.sql
\i fact/03_fact_purchase.sql
\i fact/03_fact_movement.sql
\i fact/03_fact_transaction.sql
\i fact/03_fact_stock_holding.sql
\echo 'Fact tables created successfully.'
\echo ''

-- Step 5: Create integration/staging tables
\echo 'Step 5: Creating integration tables...'
\i integration/04_integration_lineage.sql
\i integration/04_integration_city_staging.sql
\i integration/04_integration_customer_staging.sql
\i integration/04_integration_employee_staging.sql
\i integration/04_integration_payment_method_staging.sql
\i integration/04_integration_stock_item_staging.sql
\i integration/04_integration_supplier_staging.sql
\i integration/04_integration_transaction_type_staging.sql
\i integration/04_integration_sale_staging.sql
\i integration/04_integration_order_staging.sql
\i integration/04_integration_purchase_staging.sql
\i integration/04_integration_movement_staging.sql
\i integration/04_integration_transaction_staging.sql
\i integration/04_integration_stock_holding_staging.sql
\echo 'Integration tables created successfully.'
\echo ''

\echo '=== Phase 4: OLAP Schema Migration Complete ==='
\echo ''
\echo 'Summary:'
\echo '  - 4 schemas created (dimension, fact, integration, sequences)'
\echo '  - 8 sequences created for surrogate key generation'
\echo '  - 8 dimension tables created'
\echo '  - 6 fact tables created (5 partitioned, 1 non-partitioned)'
\echo '  - 14 integration/staging tables created'
\echo ''
\echo 'Next steps:'
\echo '  - Phase 5: ETL and Analytics Migration'
\echo '  - Migrate stored procedures for ETL processing'
\echo '  - Set up data loading from OLTP database'
