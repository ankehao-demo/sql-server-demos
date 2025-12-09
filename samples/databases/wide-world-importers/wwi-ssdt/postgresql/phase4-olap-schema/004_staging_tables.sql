-- Wide World Importers PostgreSQL Migration
-- Phase 4: OLAP Schema Migration (WideWorldImportersDW)
-- Script 004: Staging Tables for ETL
-- Migrated from SQL Server to PostgreSQL

-- =============================================
-- Integration.ETL_Cutoff
-- Tracks ETL cutoff times for incremental loads
-- =============================================
CREATE TABLE integration.etl_cutoff (
    table_name VARCHAR(128) NOT NULL,
    cutoff_time TIMESTAMP NOT NULL,
    CONSTRAINT pk_integration_etl_cutoff PRIMARY KEY (table_name)
);

COMMENT ON TABLE integration.etl_cutoff IS 'Tracks ETL cutoff times for incremental data loads';
COMMENT ON COLUMN integration.etl_cutoff.table_name IS 'Name of the target table';
COMMENT ON COLUMN integration.etl_cutoff.cutoff_time IS 'Last successful ETL cutoff time';

-- =============================================
-- Integration.Lineage
-- Tracks ETL lineage for data governance
-- =============================================
CREATE TABLE integration.lineage (
    lineage_key INTEGER NOT NULL DEFAULT nextval('integration.lineage_key_seq'),
    data_load_started TIMESTAMP NOT NULL,
    table_name VARCHAR(128) NOT NULL,
    data_load_completed TIMESTAMP NULL,
    was_successful BOOLEAN NOT NULL,
    source_system_cutoff_time TIMESTAMP NOT NULL,
    CONSTRAINT pk_integration_lineage PRIMARY KEY (lineage_key)
);

CREATE INDEX ix_integration_lineage_table_name ON integration.lineage(table_name);
CREATE INDEX ix_integration_lineage_data_load_started ON integration.lineage(data_load_started);

COMMENT ON TABLE integration.lineage IS 'Tracks ETL lineage for data governance and auditing';
COMMENT ON COLUMN integration.lineage.lineage_key IS 'Surrogate key for lineage tracking';
COMMENT ON COLUMN integration.lineage.was_successful IS 'Whether the ETL load was successful';

-- =============================================
-- Integration.City_Staging
-- Staging table for City dimension
-- =============================================
CREATE TABLE integration.city_staging (
    city_staging_key SERIAL PRIMARY KEY,
    wwi_city_id INTEGER NOT NULL,
    city VARCHAR(50) NOT NULL,
    state_province VARCHAR(50) NOT NULL,
    country VARCHAR(60) NOT NULL,
    continent VARCHAR(30) NOT NULL,
    sales_territory VARCHAR(50) NOT NULL,
    region VARCHAR(30) NOT NULL,
    subregion VARCHAR(30) NOT NULL,
    location geometry NULL,
    latest_recorded_population BIGINT NOT NULL,
    valid_from TIMESTAMP NOT NULL,
    valid_to TIMESTAMP NOT NULL
);

CREATE INDEX ix_integration_city_staging_wwi_city_id ON integration.city_staging(wwi_city_id);

COMMENT ON TABLE integration.city_staging IS 'Staging table for City dimension ETL';

-- =============================================
-- Integration.Customer_Staging
-- Staging table for Customer dimension
-- =============================================
CREATE TABLE integration.customer_staging (
    customer_staging_key SERIAL PRIMARY KEY,
    wwi_customer_id INTEGER NOT NULL,
    customer VARCHAR(100) NOT NULL,
    bill_to_customer VARCHAR(100) NOT NULL,
    category VARCHAR(50) NOT NULL,
    buying_group VARCHAR(50) NOT NULL,
    primary_contact VARCHAR(50) NOT NULL,
    postal_code VARCHAR(10) NOT NULL,
    valid_from TIMESTAMP NOT NULL,
    valid_to TIMESTAMP NOT NULL
);

CREATE INDEX ix_integration_customer_staging_wwi_customer_id ON integration.customer_staging(wwi_customer_id);

COMMENT ON TABLE integration.customer_staging IS 'Staging table for Customer dimension ETL';

-- =============================================
-- Integration.Employee_Staging
-- Staging table for Employee dimension
-- =============================================
CREATE TABLE integration.employee_staging (
    employee_staging_key SERIAL PRIMARY KEY,
    wwi_employee_id INTEGER NOT NULL,
    employee VARCHAR(50) NOT NULL,
    preferred_name VARCHAR(50) NOT NULL,
    is_salesperson BOOLEAN NOT NULL,
    photo BYTEA NULL,
    valid_from TIMESTAMP NOT NULL,
    valid_to TIMESTAMP NOT NULL
);

CREATE INDEX ix_integration_employee_staging_wwi_employee_id ON integration.employee_staging(wwi_employee_id);

COMMENT ON TABLE integration.employee_staging IS 'Staging table for Employee dimension ETL';

-- =============================================
-- Integration.PaymentMethod_Staging
-- Staging table for Payment Method dimension
-- =============================================
CREATE TABLE integration.payment_method_staging (
    payment_method_staging_key SERIAL PRIMARY KEY,
    wwi_payment_method_id INTEGER NOT NULL,
    payment_method VARCHAR(50) NOT NULL,
    valid_from TIMESTAMP NOT NULL,
    valid_to TIMESTAMP NOT NULL
);

CREATE INDEX ix_integration_payment_method_staging_wwi_payment_method_id ON integration.payment_method_staging(wwi_payment_method_id);

COMMENT ON TABLE integration.payment_method_staging IS 'Staging table for Payment Method dimension ETL';

-- =============================================
-- Integration.StockItem_Staging
-- Staging table for Stock Item dimension
-- =============================================
CREATE TABLE integration.stock_item_staging (
    stock_item_staging_key SERIAL PRIMARY KEY,
    wwi_stock_item_id INTEGER NOT NULL,
    stock_item VARCHAR(100) NOT NULL,
    color VARCHAR(20) NOT NULL,
    selling_package VARCHAR(50) NOT NULL,
    buying_package VARCHAR(50) NOT NULL,
    brand VARCHAR(50) NOT NULL,
    size VARCHAR(20) NOT NULL,
    lead_time_days INTEGER NOT NULL,
    quantity_per_outer INTEGER NOT NULL,
    is_chiller_stock BOOLEAN NOT NULL,
    barcode VARCHAR(50) NULL,
    tax_rate NUMERIC(18, 3) NOT NULL,
    unit_price NUMERIC(18, 2) NOT NULL,
    recommended_retail_price NUMERIC(18, 2) NULL,
    typical_weight_per_unit NUMERIC(18, 3) NOT NULL,
    photo BYTEA NULL,
    valid_from TIMESTAMP NOT NULL,
    valid_to TIMESTAMP NOT NULL
);

CREATE INDEX ix_integration_stock_item_staging_wwi_stock_item_id ON integration.stock_item_staging(wwi_stock_item_id);

COMMENT ON TABLE integration.stock_item_staging IS 'Staging table for Stock Item dimension ETL';

-- =============================================
-- Integration.Supplier_Staging
-- Staging table for Supplier dimension
-- =============================================
CREATE TABLE integration.supplier_staging (
    supplier_staging_key SERIAL PRIMARY KEY,
    wwi_supplier_id INTEGER NOT NULL,
    supplier VARCHAR(100) NOT NULL,
    category VARCHAR(50) NOT NULL,
    primary_contact VARCHAR(50) NOT NULL,
    supplier_reference VARCHAR(20) NULL,
    payment_days INTEGER NOT NULL,
    postal_code VARCHAR(10) NOT NULL,
    valid_from TIMESTAMP NOT NULL,
    valid_to TIMESTAMP NOT NULL
);

CREATE INDEX ix_integration_supplier_staging_wwi_supplier_id ON integration.supplier_staging(wwi_supplier_id);

COMMENT ON TABLE integration.supplier_staging IS 'Staging table for Supplier dimension ETL';

-- =============================================
-- Integration.TransactionType_Staging
-- Staging table for Transaction Type dimension
-- =============================================
CREATE TABLE integration.transaction_type_staging (
    transaction_type_staging_key SERIAL PRIMARY KEY,
    wwi_transaction_type_id INTEGER NOT NULL,
    transaction_type VARCHAR(50) NOT NULL,
    valid_from TIMESTAMP NOT NULL,
    valid_to TIMESTAMP NOT NULL
);

CREATE INDEX ix_integration_transaction_type_staging_wwi_transaction_type_id ON integration.transaction_type_staging(wwi_transaction_type_id);

COMMENT ON TABLE integration.transaction_type_staging IS 'Staging table for Transaction Type dimension ETL';

-- =============================================
-- Integration.Movement_Staging
-- Staging table for Movement fact
-- =============================================
CREATE TABLE integration.movement_staging (
    movement_staging_key SERIAL PRIMARY KEY,
    date_key DATE NULL,
    stock_item_key INTEGER NULL,
    customer_key INTEGER NULL,
    supplier_key INTEGER NULL,
    transaction_type_key INTEGER NULL,
    wwi_stock_item_transaction_id INTEGER NOT NULL,
    wwi_invoice_id INTEGER NULL,
    wwi_purchase_order_id INTEGER NULL,
    quantity INTEGER NOT NULL,
    wwi_stock_item_id INTEGER NULL,
    wwi_customer_id INTEGER NULL,
    wwi_supplier_id INTEGER NULL,
    wwi_transaction_type_id INTEGER NULL,
    last_modified_when TIMESTAMP NOT NULL
);

CREATE INDEX ix_integration_movement_staging_wwi_stock_item_transaction_id ON integration.movement_staging(wwi_stock_item_transaction_id);

COMMENT ON TABLE integration.movement_staging IS 'Staging table for Movement fact ETL';

-- =============================================
-- Integration.Order_Staging
-- Staging table for Order fact
-- =============================================
CREATE TABLE integration.order_staging (
    order_staging_key SERIAL PRIMARY KEY,
    city_key INTEGER NULL,
    customer_key INTEGER NULL,
    stock_item_key INTEGER NULL,
    order_date_key DATE NULL,
    picked_date_key DATE NULL,
    salesperson_key INTEGER NULL,
    picker_key INTEGER NULL,
    wwi_order_id INTEGER NOT NULL,
    wwi_backorder_id INTEGER NULL,
    description VARCHAR(100) NOT NULL,
    package VARCHAR(50) NOT NULL,
    quantity INTEGER NOT NULL,
    unit_price NUMERIC(18, 2) NOT NULL,
    tax_rate NUMERIC(18, 3) NOT NULL,
    total_excluding_tax NUMERIC(18, 2) NOT NULL,
    tax_amount NUMERIC(18, 2) NOT NULL,
    total_including_tax NUMERIC(18, 2) NOT NULL,
    wwi_city_id INTEGER NULL,
    wwi_customer_id INTEGER NULL,
    wwi_stock_item_id INTEGER NULL,
    wwi_salesperson_id INTEGER NULL,
    wwi_picker_id INTEGER NULL,
    last_modified_when TIMESTAMP NOT NULL
);

CREATE INDEX ix_integration_order_staging_wwi_order_id ON integration.order_staging(wwi_order_id);

COMMENT ON TABLE integration.order_staging IS 'Staging table for Order fact ETL';

-- =============================================
-- Integration.Purchase_Staging
-- Staging table for Purchase fact
-- =============================================
CREATE TABLE integration.purchase_staging (
    purchase_staging_key SERIAL PRIMARY KEY,
    date_key DATE NULL,
    supplier_key INTEGER NULL,
    stock_item_key INTEGER NULL,
    wwi_purchase_order_id INTEGER NULL,
    ordered_outers INTEGER NOT NULL,
    ordered_quantity INTEGER NOT NULL,
    received_outers INTEGER NOT NULL,
    package VARCHAR(50) NOT NULL,
    is_order_finalized BOOLEAN NOT NULL,
    wwi_supplier_id INTEGER NULL,
    wwi_stock_item_id INTEGER NULL,
    last_modified_when TIMESTAMP NOT NULL
);

CREATE INDEX ix_integration_purchase_staging_wwi_purchase_order_id ON integration.purchase_staging(wwi_purchase_order_id);

COMMENT ON TABLE integration.purchase_staging IS 'Staging table for Purchase fact ETL';

-- =============================================
-- Integration.Sale_Staging
-- Staging table for Sale fact
-- =============================================
CREATE TABLE integration.sale_staging (
    sale_staging_key SERIAL PRIMARY KEY,
    city_key INTEGER NULL,
    customer_key INTEGER NULL,
    bill_to_customer_key INTEGER NULL,
    stock_item_key INTEGER NULL,
    invoice_date_key DATE NULL,
    delivery_date_key DATE NULL,
    salesperson_key INTEGER NULL,
    wwi_invoice_id INTEGER NOT NULL,
    description VARCHAR(100) NOT NULL,
    package VARCHAR(50) NOT NULL,
    quantity INTEGER NOT NULL,
    unit_price NUMERIC(18, 2) NOT NULL,
    tax_rate NUMERIC(18, 3) NOT NULL,
    total_excluding_tax NUMERIC(18, 2) NOT NULL,
    tax_amount NUMERIC(18, 2) NOT NULL,
    profit NUMERIC(18, 2) NOT NULL,
    total_including_tax NUMERIC(18, 2) NOT NULL,
    total_dry_items INTEGER NOT NULL,
    total_chiller_items INTEGER NOT NULL,
    wwi_city_id INTEGER NULL,
    wwi_customer_id INTEGER NULL,
    wwi_bill_to_customer_id INTEGER NULL,
    wwi_stock_item_id INTEGER NULL,
    wwi_salesperson_id INTEGER NULL,
    last_modified_when TIMESTAMP NOT NULL
);

CREATE INDEX ix_integration_sale_staging_wwi_invoice_id ON integration.sale_staging(wwi_invoice_id);

COMMENT ON TABLE integration.sale_staging IS 'Staging table for Sale fact ETL';

-- =============================================
-- Integration.StockHolding_Staging
-- Staging table for Stock Holding fact
-- =============================================
CREATE TABLE integration.stock_holding_staging (
    stock_holding_staging_key SERIAL PRIMARY KEY,
    stock_item_key INTEGER NULL,
    quantity_on_hand INTEGER NOT NULL,
    bin_location VARCHAR(20) NOT NULL,
    last_stocktake_quantity INTEGER NOT NULL,
    last_cost_price NUMERIC(18, 2) NOT NULL,
    reorder_level INTEGER NOT NULL,
    target_stock_level INTEGER NOT NULL,
    wwi_stock_item_id INTEGER NULL
);

CREATE INDEX ix_integration_stock_holding_staging_wwi_stock_item_id ON integration.stock_holding_staging(wwi_stock_item_id);

COMMENT ON TABLE integration.stock_holding_staging IS 'Staging table for Stock Holding fact ETL';

-- =============================================
-- Integration.Transaction_Staging
-- Staging table for Transaction fact
-- =============================================
CREATE TABLE integration.transaction_staging (
    transaction_staging_key SERIAL PRIMARY KEY,
    date_key DATE NULL,
    customer_key INTEGER NULL,
    bill_to_customer_key INTEGER NULL,
    supplier_key INTEGER NULL,
    transaction_type_key INTEGER NULL,
    payment_method_key INTEGER NULL,
    wwi_customer_transaction_id INTEGER NULL,
    wwi_supplier_transaction_id INTEGER NULL,
    wwi_invoice_id INTEGER NULL,
    wwi_purchase_order_id INTEGER NULL,
    supplier_invoice_number VARCHAR(20) NULL,
    total_excluding_tax NUMERIC(18, 2) NOT NULL,
    tax_amount NUMERIC(18, 2) NOT NULL,
    total_including_tax NUMERIC(18, 2) NOT NULL,
    outstanding_balance NUMERIC(18, 2) NOT NULL,
    is_finalized BOOLEAN NOT NULL,
    wwi_customer_id INTEGER NULL,
    wwi_bill_to_customer_id INTEGER NULL,
    wwi_supplier_id INTEGER NULL,
    wwi_transaction_type_id INTEGER NULL,
    wwi_payment_method_id INTEGER NULL,
    last_modified_when TIMESTAMP NOT NULL
);

CREATE INDEX ix_integration_transaction_staging_wwi_customer_transaction_id ON integration.transaction_staging(wwi_customer_transaction_id);
CREATE INDEX ix_integration_transaction_staging_wwi_supplier_transaction_id ON integration.transaction_staging(wwi_supplier_transaction_id);

COMMENT ON TABLE integration.transaction_staging IS 'Staging table for Transaction fact ETL';
