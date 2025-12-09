-- Wide World Importers PostgreSQL Migration
-- Phase 4: OLAP Schema Migration (WideWorldImportersDW)
-- Script 003: Fact Tables
-- Migrated from SQL Server to PostgreSQL

-- =============================================
-- Fact.Movement
-- Stock movement fact table
-- =============================================
CREATE TABLE fact.movement (
    movement_key BIGINT NOT NULL DEFAULT nextval('fact.movement_key_seq'),
    date_key DATE NOT NULL,
    stock_item_key INTEGER NOT NULL,
    customer_key INTEGER NULL,
    supplier_key INTEGER NULL,
    transaction_type_key INTEGER NOT NULL,
    wwi_stock_item_transaction_id INTEGER NOT NULL,
    wwi_invoice_id INTEGER NULL,
    wwi_purchase_order_id INTEGER NULL,
    quantity INTEGER NOT NULL,
    lineage_key INTEGER NOT NULL,
    CONSTRAINT pk_fact_movement PRIMARY KEY (movement_key)
);

CREATE INDEX ix_fact_movement_date_key ON fact.movement(date_key);
CREATE INDEX ix_fact_movement_stock_item_key ON fact.movement(stock_item_key);
CREATE INDEX ix_fact_movement_customer_key ON fact.movement(customer_key);
CREATE INDEX ix_fact_movement_supplier_key ON fact.movement(supplier_key);
CREATE INDEX ix_fact_movement_transaction_type_key ON fact.movement(transaction_type_key);

ALTER TABLE fact.movement ADD CONSTRAINT fk_fact_movement_date_key 
    FOREIGN KEY (date_key) REFERENCES dimension.date(date_key);
ALTER TABLE fact.movement ADD CONSTRAINT fk_fact_movement_stock_item_key 
    FOREIGN KEY (stock_item_key) REFERENCES dimension.stock_item(stock_item_key);
ALTER TABLE fact.movement ADD CONSTRAINT fk_fact_movement_customer_key 
    FOREIGN KEY (customer_key) REFERENCES dimension.customer(customer_key);
ALTER TABLE fact.movement ADD CONSTRAINT fk_fact_movement_supplier_key 
    FOREIGN KEY (supplier_key) REFERENCES dimension.supplier(supplier_key);
ALTER TABLE fact.movement ADD CONSTRAINT fk_fact_movement_transaction_type_key 
    FOREIGN KEY (transaction_type_key) REFERENCES dimension.transaction_type(transaction_type_key);

COMMENT ON TABLE fact.movement IS 'Stock movement fact table tracking inventory changes';
COMMENT ON COLUMN fact.movement.movement_key IS 'Surrogate key for the movement fact';
COMMENT ON COLUMN fact.movement.quantity IS 'Quantity moved (positive for receipts, negative for issues)';

-- =============================================
-- Fact.Order
-- Sales order fact table
-- =============================================
CREATE TABLE fact.order (
    order_key BIGINT NOT NULL DEFAULT nextval('fact.order_key_seq'),
    city_key INTEGER NOT NULL,
    customer_key INTEGER NOT NULL,
    stock_item_key INTEGER NOT NULL,
    order_date_key DATE NOT NULL,
    picked_date_key DATE NULL,
    salesperson_key INTEGER NOT NULL,
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
    lineage_key INTEGER NOT NULL,
    CONSTRAINT pk_fact_order PRIMARY KEY (order_key)
);

CREATE INDEX ix_fact_order_city_key ON fact.order(city_key);
CREATE INDEX ix_fact_order_customer_key ON fact.order(customer_key);
CREATE INDEX ix_fact_order_stock_item_key ON fact.order(stock_item_key);
CREATE INDEX ix_fact_order_order_date_key ON fact.order(order_date_key);
CREATE INDEX ix_fact_order_picked_date_key ON fact.order(picked_date_key);
CREATE INDEX ix_fact_order_salesperson_key ON fact.order(salesperson_key);

ALTER TABLE fact.order ADD CONSTRAINT fk_fact_order_city_key 
    FOREIGN KEY (city_key) REFERENCES dimension.city(city_key);
ALTER TABLE fact.order ADD CONSTRAINT fk_fact_order_customer_key 
    FOREIGN KEY (customer_key) REFERENCES dimension.customer(customer_key);
ALTER TABLE fact.order ADD CONSTRAINT fk_fact_order_stock_item_key 
    FOREIGN KEY (stock_item_key) REFERENCES dimension.stock_item(stock_item_key);
ALTER TABLE fact.order ADD CONSTRAINT fk_fact_order_order_date_key 
    FOREIGN KEY (order_date_key) REFERENCES dimension.date(date_key);
ALTER TABLE fact.order ADD CONSTRAINT fk_fact_order_picked_date_key 
    FOREIGN KEY (picked_date_key) REFERENCES dimension.date(date_key);
ALTER TABLE fact.order ADD CONSTRAINT fk_fact_order_salesperson_key 
    FOREIGN KEY (salesperson_key) REFERENCES dimension.employee(employee_key);
ALTER TABLE fact.order ADD CONSTRAINT fk_fact_order_picker_key 
    FOREIGN KEY (picker_key) REFERENCES dimension.employee(employee_key);

COMMENT ON TABLE fact.order IS 'Sales order fact table';
COMMENT ON COLUMN fact.order.order_key IS 'Surrogate key for the order fact';
COMMENT ON COLUMN fact.order.total_including_tax IS 'Total amount including tax';

-- =============================================
-- Fact.Purchase
-- Purchase order fact table
-- =============================================
CREATE TABLE fact.purchase (
    purchase_key BIGINT NOT NULL DEFAULT nextval('fact.purchase_key_seq'),
    date_key DATE NOT NULL,
    supplier_key INTEGER NOT NULL,
    stock_item_key INTEGER NOT NULL,
    wwi_purchase_order_id INTEGER NULL,
    ordered_outers INTEGER NOT NULL,
    ordered_quantity INTEGER NOT NULL,
    received_outers INTEGER NOT NULL,
    package VARCHAR(50) NOT NULL,
    is_order_finalized BOOLEAN NOT NULL,
    lineage_key INTEGER NOT NULL,
    CONSTRAINT pk_fact_purchase PRIMARY KEY (purchase_key)
);

CREATE INDEX ix_fact_purchase_date_key ON fact.purchase(date_key);
CREATE INDEX ix_fact_purchase_supplier_key ON fact.purchase(supplier_key);
CREATE INDEX ix_fact_purchase_stock_item_key ON fact.purchase(stock_item_key);

ALTER TABLE fact.purchase ADD CONSTRAINT fk_fact_purchase_date_key 
    FOREIGN KEY (date_key) REFERENCES dimension.date(date_key);
ALTER TABLE fact.purchase ADD CONSTRAINT fk_fact_purchase_supplier_key 
    FOREIGN KEY (supplier_key) REFERENCES dimension.supplier(supplier_key);
ALTER TABLE fact.purchase ADD CONSTRAINT fk_fact_purchase_stock_item_key 
    FOREIGN KEY (stock_item_key) REFERENCES dimension.stock_item(stock_item_key);

COMMENT ON TABLE fact.purchase IS 'Purchase order fact table';
COMMENT ON COLUMN fact.purchase.purchase_key IS 'Surrogate key for the purchase fact';
COMMENT ON COLUMN fact.purchase.ordered_outers IS 'Number of outer packages ordered';
COMMENT ON COLUMN fact.purchase.ordered_quantity IS 'Total quantity ordered';

-- =============================================
-- Fact.Sale
-- Sales invoice fact table (main fact table)
-- =============================================
CREATE TABLE fact.sale (
    sale_key BIGINT NOT NULL DEFAULT nextval('fact.sale_key_seq'),
    city_key INTEGER NOT NULL,
    customer_key INTEGER NOT NULL,
    bill_to_customer_key INTEGER NOT NULL,
    stock_item_key INTEGER NOT NULL,
    invoice_date_key DATE NOT NULL,
    delivery_date_key DATE NULL,
    salesperson_key INTEGER NOT NULL,
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
    lineage_key INTEGER NOT NULL,
    CONSTRAINT pk_fact_sale PRIMARY KEY (sale_key)
);

CREATE INDEX ix_fact_sale_city_key ON fact.sale(city_key);
CREATE INDEX ix_fact_sale_customer_key ON fact.sale(customer_key);
CREATE INDEX ix_fact_sale_bill_to_customer_key ON fact.sale(bill_to_customer_key);
CREATE INDEX ix_fact_sale_stock_item_key ON fact.sale(stock_item_key);
CREATE INDEX ix_fact_sale_invoice_date_key ON fact.sale(invoice_date_key);
CREATE INDEX ix_fact_sale_delivery_date_key ON fact.sale(delivery_date_key);
CREATE INDEX ix_fact_sale_salesperson_key ON fact.sale(salesperson_key);

ALTER TABLE fact.sale ADD CONSTRAINT fk_fact_sale_city_key 
    FOREIGN KEY (city_key) REFERENCES dimension.city(city_key);
ALTER TABLE fact.sale ADD CONSTRAINT fk_fact_sale_customer_key 
    FOREIGN KEY (customer_key) REFERENCES dimension.customer(customer_key);
ALTER TABLE fact.sale ADD CONSTRAINT fk_fact_sale_bill_to_customer_key 
    FOREIGN KEY (bill_to_customer_key) REFERENCES dimension.customer(customer_key);
ALTER TABLE fact.sale ADD CONSTRAINT fk_fact_sale_stock_item_key 
    FOREIGN KEY (stock_item_key) REFERENCES dimension.stock_item(stock_item_key);
ALTER TABLE fact.sale ADD CONSTRAINT fk_fact_sale_invoice_date_key 
    FOREIGN KEY (invoice_date_key) REFERENCES dimension.date(date_key);
ALTER TABLE fact.sale ADD CONSTRAINT fk_fact_sale_delivery_date_key 
    FOREIGN KEY (delivery_date_key) REFERENCES dimension.date(date_key);
ALTER TABLE fact.sale ADD CONSTRAINT fk_fact_sale_salesperson_key 
    FOREIGN KEY (salesperson_key) REFERENCES dimension.employee(employee_key);

COMMENT ON TABLE fact.sale IS 'Sales invoice fact table - main fact table for sales analysis';
COMMENT ON COLUMN fact.sale.sale_key IS 'Surrogate key for the sale fact';
COMMENT ON COLUMN fact.sale.profit IS 'Profit margin on the sale';
COMMENT ON COLUMN fact.sale.total_including_tax IS 'Total amount including tax';

-- =============================================
-- Fact.Stock_Holding
-- Current stock holding snapshot fact table
-- =============================================
CREATE TABLE fact.stock_holding (
    stock_holding_key BIGINT NOT NULL,
    stock_item_key INTEGER NOT NULL,
    quantity_on_hand INTEGER NOT NULL,
    bin_location VARCHAR(20) NOT NULL,
    last_stocktake_quantity INTEGER NOT NULL,
    last_cost_price NUMERIC(18, 2) NOT NULL,
    reorder_level INTEGER NOT NULL,
    target_stock_level INTEGER NOT NULL,
    lineage_key INTEGER NOT NULL,
    CONSTRAINT pk_fact_stock_holding PRIMARY KEY (stock_holding_key)
);

CREATE INDEX ix_fact_stock_holding_stock_item_key ON fact.stock_holding(stock_item_key);

ALTER TABLE fact.stock_holding ADD CONSTRAINT fk_fact_stock_holding_stock_item_key 
    FOREIGN KEY (stock_item_key) REFERENCES dimension.stock_item(stock_item_key);

COMMENT ON TABLE fact.stock_holding IS 'Current stock holding snapshot fact table';
COMMENT ON COLUMN fact.stock_holding.stock_holding_key IS 'Primary key for the stock holding fact';
COMMENT ON COLUMN fact.stock_holding.quantity_on_hand IS 'Current quantity in stock';

-- =============================================
-- Fact.Transaction
-- Financial transaction fact table
-- =============================================
CREATE TABLE fact.transaction (
    transaction_key BIGINT NOT NULL DEFAULT nextval('fact.transaction_key_seq'),
    date_key DATE NOT NULL,
    customer_key INTEGER NULL,
    bill_to_customer_key INTEGER NULL,
    supplier_key INTEGER NULL,
    transaction_type_key INTEGER NOT NULL,
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
    lineage_key INTEGER NOT NULL,
    CONSTRAINT pk_fact_transaction PRIMARY KEY (transaction_key)
);

CREATE INDEX ix_fact_transaction_date_key ON fact.transaction(date_key);
CREATE INDEX ix_fact_transaction_customer_key ON fact.transaction(customer_key);
CREATE INDEX ix_fact_transaction_supplier_key ON fact.transaction(supplier_key);
CREATE INDEX ix_fact_transaction_transaction_type_key ON fact.transaction(transaction_type_key);
CREATE INDEX ix_fact_transaction_payment_method_key ON fact.transaction(payment_method_key);

ALTER TABLE fact.transaction ADD CONSTRAINT fk_fact_transaction_date_key 
    FOREIGN KEY (date_key) REFERENCES dimension.date(date_key);
ALTER TABLE fact.transaction ADD CONSTRAINT fk_fact_transaction_customer_key 
    FOREIGN KEY (customer_key) REFERENCES dimension.customer(customer_key);
ALTER TABLE fact.transaction ADD CONSTRAINT fk_fact_transaction_bill_to_customer_key 
    FOREIGN KEY (bill_to_customer_key) REFERENCES dimension.customer(customer_key);
ALTER TABLE fact.transaction ADD CONSTRAINT fk_fact_transaction_supplier_key 
    FOREIGN KEY (supplier_key) REFERENCES dimension.supplier(supplier_key);
ALTER TABLE fact.transaction ADD CONSTRAINT fk_fact_transaction_transaction_type_key 
    FOREIGN KEY (transaction_type_key) REFERENCES dimension.transaction_type(transaction_type_key);
ALTER TABLE fact.transaction ADD CONSTRAINT fk_fact_transaction_payment_method_key 
    FOREIGN KEY (payment_method_key) REFERENCES dimension.payment_method(payment_method_key);

COMMENT ON TABLE fact.transaction IS 'Financial transaction fact table';
COMMENT ON COLUMN fact.transaction.transaction_key IS 'Surrogate key for the transaction fact';
COMMENT ON COLUMN fact.transaction.outstanding_balance IS 'Outstanding balance on the transaction';
COMMENT ON COLUMN fact.transaction.is_finalized IS 'Whether the transaction has been finalized';
