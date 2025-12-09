-- Wide World Importers DW PostgreSQL Migration
-- Phase 4: OLAP Schema Migration
-- File: 001-staging-tables.sql
-- Description: Create all staging tables for ETL processes
-- Note: SQL Server uses memory-optimized tables (MEMORY_OPTIMIZED = ON, DURABILITY = SCHEMA_ONLY)
-- PostgreSQL uses UNLOGGED tables for similar performance characteristics (no WAL logging)

-- =============================================
-- Integration.City_Staging - Staging table for City dimension ETL
-- =============================================
CREATE UNLOGGED TABLE integration.city_staging (
    city_staging_key bigserial NOT NULL,
    city_key integer NULL,
    wwi_city_id integer NULL,
    city varchar(50) NULL,
    state_province varchar(50) NULL,
    country varchar(60) NULL,
    continent varchar(30) NULL,
    sales_territory varchar(50) NULL,
    region varchar(30) NULL,
    subregion varchar(30) NULL,
    location geography NULL,
    latest_recorded_population bigint NULL,
    valid_from timestamp NULL,
    valid_to timestamp NULL,
    CONSTRAINT pk_integration_city_staging PRIMARY KEY (city_staging_key)
);

COMMENT ON TABLE integration.city_staging IS 'Staging table for City dimension ETL';

-- =============================================
-- Integration.Customer_Staging - Staging table for Customer dimension ETL
-- =============================================
CREATE UNLOGGED TABLE integration.customer_staging (
    customer_staging_key bigserial NOT NULL,
    customer_key integer NULL,
    wwi_customer_id integer NULL,
    customer varchar(100) NULL,
    bill_to_customer varchar(100) NULL,
    category varchar(50) NULL,
    buying_group varchar(50) NULL,
    primary_contact varchar(50) NULL,
    postal_code varchar(10) NULL,
    valid_from timestamp NULL,
    valid_to timestamp NULL,
    CONSTRAINT pk_integration_customer_staging PRIMARY KEY (customer_staging_key)
);

COMMENT ON TABLE integration.customer_staging IS 'Staging table for Customer dimension ETL';

-- =============================================
-- Integration.Employee_Staging - Staging table for Employee dimension ETL
-- =============================================
CREATE UNLOGGED TABLE integration.employee_staging (
    employee_staging_key bigserial NOT NULL,
    employee_key integer NULL,
    wwi_employee_id integer NULL,
    employee varchar(50) NULL,
    preferred_name varchar(50) NULL,
    is_salesperson boolean NULL,
    photo bytea NULL,
    valid_from timestamp NULL,
    valid_to timestamp NULL,
    CONSTRAINT pk_integration_employee_staging PRIMARY KEY (employee_staging_key)
);

COMMENT ON TABLE integration.employee_staging IS 'Staging table for Employee dimension ETL';

-- =============================================
-- Integration.Payment_Method_Staging - Staging table for Payment Method dimension ETL
-- =============================================
CREATE UNLOGGED TABLE integration.payment_method_staging (
    payment_method_staging_key bigserial NOT NULL,
    payment_method_key integer NULL,
    wwi_payment_method_id integer NULL,
    payment_method varchar(50) NULL,
    valid_from timestamp NULL,
    valid_to timestamp NULL,
    CONSTRAINT pk_integration_payment_method_staging PRIMARY KEY (payment_method_staging_key)
);

COMMENT ON TABLE integration.payment_method_staging IS 'Staging table for Payment Method dimension ETL';

-- =============================================
-- Integration.Stock_Item_Staging - Staging table for Stock Item dimension ETL
-- =============================================
CREATE UNLOGGED TABLE integration.stock_item_staging (
    stock_item_staging_key bigserial NOT NULL,
    stock_item_key integer NULL,
    wwi_stock_item_id integer NULL,
    stock_item varchar(100) NULL,
    color varchar(20) NULL,
    selling_package varchar(50) NULL,
    buying_package varchar(50) NULL,
    brand varchar(50) NULL,
    size varchar(20) NULL,
    lead_time_days integer NULL,
    quantity_per_outer integer NULL,
    is_chiller_stock boolean NULL,
    barcode varchar(50) NULL,
    tax_rate numeric(18,3) NULL,
    unit_price numeric(18,2) NULL,
    recommended_retail_price numeric(18,2) NULL,
    typical_weight_per_unit numeric(18,3) NULL,
    photo bytea NULL,
    valid_from timestamp NULL,
    valid_to timestamp NULL,
    CONSTRAINT pk_integration_stock_item_staging PRIMARY KEY (stock_item_staging_key)
);

COMMENT ON TABLE integration.stock_item_staging IS 'Staging table for Stock Item dimension ETL';

-- =============================================
-- Integration.Supplier_Staging - Staging table for Supplier dimension ETL
-- =============================================
CREATE UNLOGGED TABLE integration.supplier_staging (
    supplier_staging_key bigserial NOT NULL,
    supplier_key integer NULL,
    wwi_supplier_id integer NULL,
    supplier varchar(100) NULL,
    category varchar(50) NULL,
    primary_contact varchar(50) NULL,
    supplier_reference varchar(20) NULL,
    payment_days integer NULL,
    postal_code varchar(10) NULL,
    valid_from timestamp NULL,
    valid_to timestamp NULL,
    CONSTRAINT pk_integration_supplier_staging PRIMARY KEY (supplier_staging_key)
);

COMMENT ON TABLE integration.supplier_staging IS 'Staging table for Supplier dimension ETL';

-- =============================================
-- Integration.Transaction_Type_Staging - Staging table for Transaction Type dimension ETL
-- =============================================
CREATE UNLOGGED TABLE integration.transaction_type_staging (
    transaction_type_staging_key bigserial NOT NULL,
    transaction_type_key integer NULL,
    wwi_transaction_type_id integer NULL,
    transaction_type varchar(50) NULL,
    valid_from timestamp NULL,
    valid_to timestamp NULL,
    CONSTRAINT pk_integration_transaction_type_staging PRIMARY KEY (transaction_type_staging_key)
);

COMMENT ON TABLE integration.transaction_type_staging IS 'Staging table for Transaction Type dimension ETL';

-- =============================================
-- Integration.Sale_Staging - Staging table for Sale fact ETL
-- =============================================
CREATE UNLOGGED TABLE integration.sale_staging (
    sale_staging_key bigserial NOT NULL,
    city_key integer NULL,
    customer_key integer NULL,
    bill_to_customer_key integer NULL,
    stock_item_key integer NULL,
    invoice_date_key date NULL,
    delivery_date_key date NULL,
    salesperson_key integer NULL,
    wwi_invoice_id integer NULL,
    description varchar(100) NULL,
    package varchar(50) NULL,
    quantity integer NULL,
    unit_price numeric(18,2) NULL,
    tax_rate numeric(18,3) NULL,
    total_excluding_tax numeric(18,2) NULL,
    tax_amount numeric(18,2) NULL,
    profit numeric(18,2) NULL,
    total_including_tax numeric(18,2) NULL,
    total_dry_items integer NULL,
    total_chiller_items integer NULL,
    wwi_city_id integer NULL,
    wwi_customer_id integer NULL,
    wwi_bill_to_customer_id integer NULL,
    wwi_stock_item_id integer NULL,
    wwi_salesperson_id integer NULL,
    last_modified_when timestamp NULL,
    CONSTRAINT pk_integration_sale_staging PRIMARY KEY (sale_staging_key)
);

COMMENT ON TABLE integration.sale_staging IS 'Staging table for Sale fact ETL';

-- =============================================
-- Integration.Order_Staging - Staging table for Order fact ETL
-- =============================================
CREATE UNLOGGED TABLE integration.order_staging (
    order_staging_key bigserial NOT NULL,
    city_key integer NULL,
    customer_key integer NULL,
    stock_item_key integer NULL,
    order_date_key date NULL,
    picked_date_key date NULL,
    salesperson_key integer NULL,
    picker_key integer NULL,
    wwi_order_id integer NULL,
    wwi_backorder_id integer NULL,
    description varchar(100) NULL,
    package varchar(50) NULL,
    quantity integer NULL,
    unit_price numeric(18,2) NULL,
    tax_rate numeric(18,3) NULL,
    total_excluding_tax numeric(18,2) NULL,
    tax_amount numeric(18,2) NULL,
    total_including_tax numeric(18,2) NULL,
    wwi_city_id integer NULL,
    wwi_customer_id integer NULL,
    wwi_stock_item_id integer NULL,
    wwi_salesperson_id integer NULL,
    wwi_picker_id integer NULL,
    last_modified_when timestamp NULL,
    CONSTRAINT pk_integration_order_staging PRIMARY KEY (order_staging_key)
);

COMMENT ON TABLE integration.order_staging IS 'Staging table for Order fact ETL';

-- =============================================
-- Integration.Purchase_Staging - Staging table for Purchase fact ETL
-- =============================================
CREATE UNLOGGED TABLE integration.purchase_staging (
    purchase_staging_key bigserial NOT NULL,
    date_key date NULL,
    supplier_key integer NULL,
    stock_item_key integer NULL,
    wwi_purchase_order_id integer NULL,
    ordered_outers integer NULL,
    ordered_quantity integer NULL,
    received_outers integer NULL,
    package varchar(50) NULL,
    is_order_finalized boolean NULL,
    wwi_supplier_id integer NULL,
    wwi_stock_item_id integer NULL,
    last_modified_when timestamp NULL,
    CONSTRAINT pk_integration_purchase_staging PRIMARY KEY (purchase_staging_key)
);

COMMENT ON TABLE integration.purchase_staging IS 'Staging table for Purchase fact ETL';

-- =============================================
-- Integration.Movement_Staging - Staging table for Movement fact ETL
-- =============================================
CREATE UNLOGGED TABLE integration.movement_staging (
    movement_staging_key bigserial NOT NULL,
    date_key date NULL,
    stock_item_key integer NULL,
    customer_key integer NULL,
    supplier_key integer NULL,
    transaction_type_key integer NULL,
    wwi_stock_item_transaction_id integer NULL,
    wwi_invoice_id integer NULL,
    wwi_purchase_order_id integer NULL,
    quantity integer NULL,
    wwi_stock_item_id integer NULL,
    wwi_customer_id integer NULL,
    wwi_supplier_id integer NULL,
    wwi_transaction_type_id integer NULL,
    last_modified_when timestamp NULL,
    CONSTRAINT pk_integration_movement_staging PRIMARY KEY (movement_staging_key)
);

COMMENT ON TABLE integration.movement_staging IS 'Staging table for Movement fact ETL';

-- =============================================
-- Integration.Transaction_Staging - Staging table for Transaction fact ETL
-- =============================================
CREATE UNLOGGED TABLE integration.transaction_staging (
    transaction_staging_key bigserial NOT NULL,
    date_key date NULL,
    customer_key integer NULL,
    bill_to_customer_key integer NULL,
    supplier_key integer NULL,
    transaction_type_key integer NULL,
    payment_method_key integer NULL,
    wwi_customer_transaction_id integer NULL,
    wwi_supplier_transaction_id integer NULL,
    wwi_invoice_id integer NULL,
    wwi_purchase_order_id integer NULL,
    supplier_invoice_number varchar(20) NULL,
    total_excluding_tax numeric(18,2) NULL,
    tax_amount numeric(18,2) NULL,
    total_including_tax numeric(18,2) NULL,
    outstanding_balance numeric(18,2) NULL,
    is_finalized boolean NULL,
    wwi_customer_id integer NULL,
    wwi_bill_to_customer_id integer NULL,
    wwi_supplier_id integer NULL,
    wwi_transaction_type_id integer NULL,
    wwi_payment_method_id integer NULL,
    last_modified_when timestamp NULL,
    CONSTRAINT pk_integration_transaction_staging PRIMARY KEY (transaction_staging_key)
);

COMMENT ON TABLE integration.transaction_staging IS 'Staging table for Transaction fact ETL';

-- =============================================
-- Integration.Stock_Holding_Staging - Staging table for Stock Holding fact ETL
-- =============================================
CREATE UNLOGGED TABLE integration.stock_holding_staging (
    stock_holding_staging_key bigserial NOT NULL,
    stock_item_key integer NULL,
    quantity_on_hand integer NULL,
    bin_location varchar(20) NULL,
    last_stocktake_quantity integer NULL,
    last_cost_price numeric(18,2) NULL,
    reorder_level integer NULL,
    target_stock_level integer NULL,
    wwi_stock_item_id integer NULL,
    last_modified_when timestamp NULL,
    CONSTRAINT pk_integration_stock_holding_staging PRIMARY KEY (stock_holding_staging_key)
);

COMMENT ON TABLE integration.stock_holding_staging IS 'Staging table for Stock Holding fact ETL';
