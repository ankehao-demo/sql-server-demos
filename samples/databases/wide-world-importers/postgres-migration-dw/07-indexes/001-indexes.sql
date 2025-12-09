-- Wide World Importers DW PostgreSQL Migration
-- Phase 4: OLAP Schema Migration
-- File: 001-indexes.sql
-- Description: Create indexes for data warehouse tables
-- Note: SQL Server uses clustered columnstore indexes for fact tables
-- PostgreSQL doesn't support columnstore, so we use B-tree and BRIN indexes

-- =============================================
-- Dimension Table Indexes
-- =============================================

-- City dimension indexes (already created in dimension tables file)
-- Additional indexes for common query patterns
CREATE INDEX IF NOT EXISTS ix_dimension_city_sales_territory 
    ON dimension.city (sales_territory);
CREATE INDEX IF NOT EXISTS ix_dimension_city_country 
    ON dimension.city (country);

-- Customer dimension indexes
CREATE INDEX IF NOT EXISTS ix_dimension_customer_category 
    ON dimension.customer (category);
CREATE INDEX IF NOT EXISTS ix_dimension_customer_buying_group 
    ON dimension.customer (buying_group);

-- Date dimension indexes
CREATE INDEX IF NOT EXISTS ix_dimension_date_calendar_year 
    ON dimension.date (calendar_year);
CREATE INDEX IF NOT EXISTS ix_dimension_date_fiscal_year 
    ON dimension.date (fiscal_year);
CREATE INDEX IF NOT EXISTS ix_dimension_date_calendar_month 
    ON dimension.date (calendar_year, calendar_month_number);

-- Employee dimension indexes
CREATE INDEX IF NOT EXISTS ix_dimension_employee_is_salesperson 
    ON dimension.employee (is_salesperson) WHERE is_salesperson = true;

-- Stock Item dimension indexes
CREATE INDEX IF NOT EXISTS ix_dimension_stock_item_brand 
    ON dimension.stock_item (brand);
CREATE INDEX IF NOT EXISTS ix_dimension_stock_item_color 
    ON dimension.stock_item (color);

-- Supplier dimension indexes
CREATE INDEX IF NOT EXISTS ix_dimension_supplier_category 
    ON dimension.supplier (category);

-- =============================================
-- Fact Table Indexes
-- Note: Using BRIN indexes for date columns in partitioned tables
-- BRIN indexes are efficient for large, naturally ordered data
-- =============================================

-- Sale fact indexes
CREATE INDEX IF NOT EXISTS ix_fact_sale_city_key 
    ON fact.sale (city_key);
CREATE INDEX IF NOT EXISTS ix_fact_sale_customer_key 
    ON fact.sale (customer_key);
CREATE INDEX IF NOT EXISTS ix_fact_sale_stock_item_key 
    ON fact.sale (stock_item_key);
CREATE INDEX IF NOT EXISTS ix_fact_sale_salesperson_key 
    ON fact.sale (salesperson_key);
CREATE INDEX IF NOT EXISTS ix_fact_sale_invoice_date_key_brin 
    ON fact.sale USING BRIN (invoice_date_key);

-- Order fact indexes
CREATE INDEX IF NOT EXISTS ix_fact_order_city_key 
    ON fact.order (city_key);
CREATE INDEX IF NOT EXISTS ix_fact_order_customer_key 
    ON fact.order (customer_key);
CREATE INDEX IF NOT EXISTS ix_fact_order_stock_item_key 
    ON fact.order (stock_item_key);
CREATE INDEX IF NOT EXISTS ix_fact_order_salesperson_key 
    ON fact.order (salesperson_key);
CREATE INDEX IF NOT EXISTS ix_fact_order_order_date_key_brin 
    ON fact.order USING BRIN (order_date_key);

-- Purchase fact indexes
CREATE INDEX IF NOT EXISTS ix_fact_purchase_supplier_key 
    ON fact.purchase (supplier_key);
CREATE INDEX IF NOT EXISTS ix_fact_purchase_stock_item_key 
    ON fact.purchase (stock_item_key);
CREATE INDEX IF NOT EXISTS ix_fact_purchase_date_key_brin 
    ON fact.purchase USING BRIN (date_key);

-- Movement fact indexes
CREATE INDEX IF NOT EXISTS ix_fact_movement_stock_item_key 
    ON fact.movement (stock_item_key);
CREATE INDEX IF NOT EXISTS ix_fact_movement_customer_key 
    ON fact.movement (customer_key);
CREATE INDEX IF NOT EXISTS ix_fact_movement_supplier_key 
    ON fact.movement (supplier_key);
CREATE INDEX IF NOT EXISTS ix_fact_movement_transaction_type_key 
    ON fact.movement (transaction_type_key);
CREATE INDEX IF NOT EXISTS ix_fact_movement_date_key_brin 
    ON fact.movement USING BRIN (date_key);

-- Transaction fact indexes
CREATE INDEX IF NOT EXISTS ix_fact_transaction_customer_key 
    ON fact.transaction (customer_key);
CREATE INDEX IF NOT EXISTS ix_fact_transaction_supplier_key 
    ON fact.transaction (supplier_key);
CREATE INDEX IF NOT EXISTS ix_fact_transaction_transaction_type_key 
    ON fact.transaction (transaction_type_key);
CREATE INDEX IF NOT EXISTS ix_fact_transaction_payment_method_key 
    ON fact.transaction (payment_method_key);
CREATE INDEX IF NOT EXISTS ix_fact_transaction_date_key_brin 
    ON fact.transaction USING BRIN (date_key);

-- Stock Holding fact indexes
CREATE INDEX IF NOT EXISTS ix_fact_stock_holding_stock_item_key 
    ON fact.stock_holding (stock_item_key);
