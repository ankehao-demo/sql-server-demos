-- Wide World Importers DW PostgreSQL Migration
-- Phase 4: OLAP Schema Migration
-- File: 001-fact-tables.sql
-- Description: Create all fact tables for the star schema
-- Note: SQL Server uses clustered columnstore indexes which PostgreSQL doesn't support
-- We use regular B-tree indexes and consider BRIN indexes for large date-partitioned tables

-- =============================================
-- Fact.Sale - Sales fact table (partitioned by invoice_date_key)
-- =============================================
CREATE TABLE fact.sale (
    sale_key bigserial NOT NULL,
    city_key integer NOT NULL,
    customer_key integer NOT NULL,
    bill_to_customer_key integer NOT NULL,
    stock_item_key integer NOT NULL,
    invoice_date_key date NOT NULL,
    delivery_date_key date NULL,
    salesperson_key integer NOT NULL,
    wwi_invoice_id integer NOT NULL,
    description varchar(100) NOT NULL,
    package varchar(50) NOT NULL,
    quantity integer NOT NULL,
    unit_price numeric(18,2) NOT NULL,
    tax_rate numeric(18,3) NOT NULL,
    total_excluding_tax numeric(18,2) NOT NULL,
    tax_amount numeric(18,2) NOT NULL,
    profit numeric(18,2) NOT NULL,
    total_including_tax numeric(18,2) NOT NULL,
    total_dry_items integer NOT NULL,
    total_chiller_items integer NOT NULL,
    lineage_key integer NOT NULL,
    CONSTRAINT pk_fact_sale PRIMARY KEY (sale_key, invoice_date_key)
) PARTITION BY RANGE (invoice_date_key);

-- Create partitions for years 2012-2025
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
CREATE TABLE fact.sale_2018 PARTITION OF fact.sale
    FOR VALUES FROM ('2018-01-01') TO ('2019-01-01');
CREATE TABLE fact.sale_2019 PARTITION OF fact.sale
    FOR VALUES FROM ('2019-01-01') TO ('2020-01-01');
CREATE TABLE fact.sale_2020 PARTITION OF fact.sale
    FOR VALUES FROM ('2020-01-01') TO ('2021-01-01');
CREATE TABLE fact.sale_2021 PARTITION OF fact.sale
    FOR VALUES FROM ('2021-01-01') TO ('2022-01-01');
CREATE TABLE fact.sale_2022 PARTITION OF fact.sale
    FOR VALUES FROM ('2022-01-01') TO ('2023-01-01');
CREATE TABLE fact.sale_2023 PARTITION OF fact.sale
    FOR VALUES FROM ('2023-01-01') TO ('2024-01-01');
CREATE TABLE fact.sale_2024 PARTITION OF fact.sale
    FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');
CREATE TABLE fact.sale_2025 PARTITION OF fact.sale
    FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');

COMMENT ON TABLE fact.sale IS 'Sale fact';
COMMENT ON COLUMN fact.sale.sale_key IS 'DW key for a row in the Sale fact';
COMMENT ON COLUMN fact.sale.city_key IS 'City for this sale';
COMMENT ON COLUMN fact.sale.customer_key IS 'Customer for this sale';
COMMENT ON COLUMN fact.sale.bill_to_customer_key IS 'Bill To Customer for this sale';
COMMENT ON COLUMN fact.sale.stock_item_key IS 'Stock item for this sale';
COMMENT ON COLUMN fact.sale.invoice_date_key IS 'Invoice date for this sale';
COMMENT ON COLUMN fact.sale.delivery_date_key IS 'Date that these items were delivered';
COMMENT ON COLUMN fact.sale.salesperson_key IS 'Salesperson for this sale';
COMMENT ON COLUMN fact.sale.wwi_invoice_id IS 'InvoiceID in source system';
COMMENT ON COLUMN fact.sale.description IS 'Description of the item supplied (Usually the stock item name but can be overridden)';
COMMENT ON COLUMN fact.sale.package IS 'Type of package supplied';
COMMENT ON COLUMN fact.sale.quantity IS 'Quantity supplied';
COMMENT ON COLUMN fact.sale.unit_price IS 'Unit price charged';
COMMENT ON COLUMN fact.sale.tax_rate IS 'Tax rate applied';
COMMENT ON COLUMN fact.sale.total_excluding_tax IS 'Total amount excluding tax';
COMMENT ON COLUMN fact.sale.tax_amount IS 'Total amount of tax';
COMMENT ON COLUMN fact.sale.profit IS 'Total amount of profit';
COMMENT ON COLUMN fact.sale.total_including_tax IS 'Total amount including tax';
COMMENT ON COLUMN fact.sale.total_dry_items IS 'Total number of dry items';
COMMENT ON COLUMN fact.sale.total_chiller_items IS 'Total number of chiller items';
COMMENT ON COLUMN fact.sale.lineage_key IS 'Lineage Key for the data load for this row';

-- =============================================
-- Fact.Order - Order fact table (partitioned by order_date_key)
-- =============================================
CREATE TABLE fact.order (
    order_key bigserial NOT NULL,
    city_key integer NOT NULL,
    customer_key integer NOT NULL,
    stock_item_key integer NOT NULL,
    order_date_key date NOT NULL,
    picked_date_key date NULL,
    salesperson_key integer NOT NULL,
    picker_key integer NULL,
    wwi_order_id integer NOT NULL,
    wwi_backorder_id integer NULL,
    description varchar(100) NOT NULL,
    package varchar(50) NOT NULL,
    quantity integer NOT NULL,
    unit_price numeric(18,2) NOT NULL,
    tax_rate numeric(18,3) NOT NULL,
    total_excluding_tax numeric(18,2) NOT NULL,
    tax_amount numeric(18,2) NOT NULL,
    total_including_tax numeric(18,2) NOT NULL,
    lineage_key integer NOT NULL,
    CONSTRAINT pk_fact_order PRIMARY KEY (order_key, order_date_key)
) PARTITION BY RANGE (order_date_key);

-- Create partitions for years 2012-2025
CREATE TABLE fact.order_2012 PARTITION OF fact.order
    FOR VALUES FROM ('2012-01-01') TO ('2013-01-01');
CREATE TABLE fact.order_2013 PARTITION OF fact.order
    FOR VALUES FROM ('2013-01-01') TO ('2014-01-01');
CREATE TABLE fact.order_2014 PARTITION OF fact.order
    FOR VALUES FROM ('2014-01-01') TO ('2015-01-01');
CREATE TABLE fact.order_2015 PARTITION OF fact.order
    FOR VALUES FROM ('2015-01-01') TO ('2016-01-01');
CREATE TABLE fact.order_2016 PARTITION OF fact.order
    FOR VALUES FROM ('2016-01-01') TO ('2017-01-01');
CREATE TABLE fact.order_2017 PARTITION OF fact.order
    FOR VALUES FROM ('2017-01-01') TO ('2018-01-01');
CREATE TABLE fact.order_2018 PARTITION OF fact.order
    FOR VALUES FROM ('2018-01-01') TO ('2019-01-01');
CREATE TABLE fact.order_2019 PARTITION OF fact.order
    FOR VALUES FROM ('2019-01-01') TO ('2020-01-01');
CREATE TABLE fact.order_2020 PARTITION OF fact.order
    FOR VALUES FROM ('2020-01-01') TO ('2021-01-01');
CREATE TABLE fact.order_2021 PARTITION OF fact.order
    FOR VALUES FROM ('2021-01-01') TO ('2022-01-01');
CREATE TABLE fact.order_2022 PARTITION OF fact.order
    FOR VALUES FROM ('2022-01-01') TO ('2023-01-01');
CREATE TABLE fact.order_2023 PARTITION OF fact.order
    FOR VALUES FROM ('2023-01-01') TO ('2024-01-01');
CREATE TABLE fact.order_2024 PARTITION OF fact.order
    FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');
CREATE TABLE fact.order_2025 PARTITION OF fact.order
    FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');

COMMENT ON TABLE fact.order IS 'Order fact';
COMMENT ON COLUMN fact.order.order_key IS 'DW key for a row in the Order fact';
COMMENT ON COLUMN fact.order.city_key IS 'City for this order';
COMMENT ON COLUMN fact.order.customer_key IS 'Customer for this order';
COMMENT ON COLUMN fact.order.stock_item_key IS 'Stock item for this order';
COMMENT ON COLUMN fact.order.order_date_key IS 'Order date for this order';
COMMENT ON COLUMN fact.order.picked_date_key IS 'Picked date for this order';
COMMENT ON COLUMN fact.order.salesperson_key IS 'Salesperson for this order';
COMMENT ON COLUMN fact.order.picker_key IS 'Picker for this order';
COMMENT ON COLUMN fact.order.wwi_order_id IS 'OrderID in source system';
COMMENT ON COLUMN fact.order.wwi_backorder_id IS 'BackorderID in source system';
COMMENT ON COLUMN fact.order.description IS 'Description of the item supplied';
COMMENT ON COLUMN fact.order.package IS 'Type of package supplied';
COMMENT ON COLUMN fact.order.quantity IS 'Quantity supplied';
COMMENT ON COLUMN fact.order.unit_price IS 'Unit price charged';
COMMENT ON COLUMN fact.order.tax_rate IS 'Tax rate applied';
COMMENT ON COLUMN fact.order.total_excluding_tax IS 'Total amount excluding tax';
COMMENT ON COLUMN fact.order.tax_amount IS 'Total amount of tax';
COMMENT ON COLUMN fact.order.total_including_tax IS 'Total amount including tax';
COMMENT ON COLUMN fact.order.lineage_key IS 'Lineage Key for the data load for this row';

-- =============================================
-- Fact.Purchase - Purchase fact table (partitioned by date_key)
-- =============================================
CREATE TABLE fact.purchase (
    purchase_key bigserial NOT NULL,
    date_key date NOT NULL,
    supplier_key integer NOT NULL,
    stock_item_key integer NOT NULL,
    wwi_purchase_order_id integer NULL,
    ordered_outers integer NOT NULL,
    ordered_quantity integer NOT NULL,
    received_outers integer NOT NULL,
    package varchar(50) NOT NULL,
    is_order_finalized boolean NOT NULL,
    lineage_key integer NOT NULL,
    CONSTRAINT pk_fact_purchase PRIMARY KEY (purchase_key, date_key)
) PARTITION BY RANGE (date_key);

-- Create partitions for years 2012-2025
CREATE TABLE fact.purchase_2012 PARTITION OF fact.purchase
    FOR VALUES FROM ('2012-01-01') TO ('2013-01-01');
CREATE TABLE fact.purchase_2013 PARTITION OF fact.purchase
    FOR VALUES FROM ('2013-01-01') TO ('2014-01-01');
CREATE TABLE fact.purchase_2014 PARTITION OF fact.purchase
    FOR VALUES FROM ('2014-01-01') TO ('2015-01-01');
CREATE TABLE fact.purchase_2015 PARTITION OF fact.purchase
    FOR VALUES FROM ('2015-01-01') TO ('2016-01-01');
CREATE TABLE fact.purchase_2016 PARTITION OF fact.purchase
    FOR VALUES FROM ('2016-01-01') TO ('2017-01-01');
CREATE TABLE fact.purchase_2017 PARTITION OF fact.purchase
    FOR VALUES FROM ('2017-01-01') TO ('2018-01-01');
CREATE TABLE fact.purchase_2018 PARTITION OF fact.purchase
    FOR VALUES FROM ('2018-01-01') TO ('2019-01-01');
CREATE TABLE fact.purchase_2019 PARTITION OF fact.purchase
    FOR VALUES FROM ('2019-01-01') TO ('2020-01-01');
CREATE TABLE fact.purchase_2020 PARTITION OF fact.purchase
    FOR VALUES FROM ('2020-01-01') TO ('2021-01-01');
CREATE TABLE fact.purchase_2021 PARTITION OF fact.purchase
    FOR VALUES FROM ('2021-01-01') TO ('2022-01-01');
CREATE TABLE fact.purchase_2022 PARTITION OF fact.purchase
    FOR VALUES FROM ('2022-01-01') TO ('2023-01-01');
CREATE TABLE fact.purchase_2023 PARTITION OF fact.purchase
    FOR VALUES FROM ('2023-01-01') TO ('2024-01-01');
CREATE TABLE fact.purchase_2024 PARTITION OF fact.purchase
    FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');
CREATE TABLE fact.purchase_2025 PARTITION OF fact.purchase
    FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');

COMMENT ON TABLE fact.purchase IS 'Purchase fact';
COMMENT ON COLUMN fact.purchase.purchase_key IS 'DW key for a row in the Purchase fact';
COMMENT ON COLUMN fact.purchase.date_key IS 'Date for this purchase';
COMMENT ON COLUMN fact.purchase.supplier_key IS 'Supplier for this purchase';
COMMENT ON COLUMN fact.purchase.stock_item_key IS 'Stock item for this purchase';
COMMENT ON COLUMN fact.purchase.wwi_purchase_order_id IS 'PurchaseOrderID in source system';
COMMENT ON COLUMN fact.purchase.ordered_outers IS 'Quantity of outers ordered';
COMMENT ON COLUMN fact.purchase.ordered_quantity IS 'Quantity ordered';
COMMENT ON COLUMN fact.purchase.received_outers IS 'Quantity of outers received';
COMMENT ON COLUMN fact.purchase.package IS 'Package type';
COMMENT ON COLUMN fact.purchase.is_order_finalized IS 'Is this purchase order now finalized?';
COMMENT ON COLUMN fact.purchase.lineage_key IS 'Lineage Key for the data load for this row';

-- =============================================
-- Fact.Movement - Stock movement fact table (partitioned by date_key)
-- =============================================
CREATE TABLE fact.movement (
    movement_key bigserial NOT NULL,
    date_key date NOT NULL,
    stock_item_key integer NOT NULL,
    customer_key integer NULL,
    supplier_key integer NULL,
    transaction_type_key integer NOT NULL,
    wwi_stock_item_transaction_id integer NOT NULL,
    wwi_invoice_id integer NULL,
    wwi_purchase_order_id integer NULL,
    quantity integer NOT NULL,
    lineage_key integer NOT NULL,
    CONSTRAINT pk_fact_movement PRIMARY KEY (movement_key, date_key)
) PARTITION BY RANGE (date_key);

-- Create partitions for years 2012-2025
CREATE TABLE fact.movement_2012 PARTITION OF fact.movement
    FOR VALUES FROM ('2012-01-01') TO ('2013-01-01');
CREATE TABLE fact.movement_2013 PARTITION OF fact.movement
    FOR VALUES FROM ('2013-01-01') TO ('2014-01-01');
CREATE TABLE fact.movement_2014 PARTITION OF fact.movement
    FOR VALUES FROM ('2014-01-01') TO ('2015-01-01');
CREATE TABLE fact.movement_2015 PARTITION OF fact.movement
    FOR VALUES FROM ('2015-01-01') TO ('2016-01-01');
CREATE TABLE fact.movement_2016 PARTITION OF fact.movement
    FOR VALUES FROM ('2016-01-01') TO ('2017-01-01');
CREATE TABLE fact.movement_2017 PARTITION OF fact.movement
    FOR VALUES FROM ('2017-01-01') TO ('2018-01-01');
CREATE TABLE fact.movement_2018 PARTITION OF fact.movement
    FOR VALUES FROM ('2018-01-01') TO ('2019-01-01');
CREATE TABLE fact.movement_2019 PARTITION OF fact.movement
    FOR VALUES FROM ('2019-01-01') TO ('2020-01-01');
CREATE TABLE fact.movement_2020 PARTITION OF fact.movement
    FOR VALUES FROM ('2020-01-01') TO ('2021-01-01');
CREATE TABLE fact.movement_2021 PARTITION OF fact.movement
    FOR VALUES FROM ('2021-01-01') TO ('2022-01-01');
CREATE TABLE fact.movement_2022 PARTITION OF fact.movement
    FOR VALUES FROM ('2022-01-01') TO ('2023-01-01');
CREATE TABLE fact.movement_2023 PARTITION OF fact.movement
    FOR VALUES FROM ('2023-01-01') TO ('2024-01-01');
CREATE TABLE fact.movement_2024 PARTITION OF fact.movement
    FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');
CREATE TABLE fact.movement_2025 PARTITION OF fact.movement
    FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');

COMMENT ON TABLE fact.movement IS 'Movement fact';
COMMENT ON COLUMN fact.movement.movement_key IS 'DW key for a row in the Movement fact';
COMMENT ON COLUMN fact.movement.date_key IS 'Date for this movement';
COMMENT ON COLUMN fact.movement.stock_item_key IS 'Stock item for this movement';
COMMENT ON COLUMN fact.movement.customer_key IS 'Customer (if applicable)';
COMMENT ON COLUMN fact.movement.supplier_key IS 'Supplier (if applicable)';
COMMENT ON COLUMN fact.movement.transaction_type_key IS 'Transaction type for this movement';
COMMENT ON COLUMN fact.movement.wwi_stock_item_transaction_id IS 'StockItemTransactionID in source system';
COMMENT ON COLUMN fact.movement.wwi_invoice_id IS 'InvoiceID in source system (if applicable)';
COMMENT ON COLUMN fact.movement.wwi_purchase_order_id IS 'PurchaseOrderID in source system (if applicable)';
COMMENT ON COLUMN fact.movement.quantity IS 'Quantity of stock movement (positive is incoming stock, negative is outgoing)';
COMMENT ON COLUMN fact.movement.lineage_key IS 'Lineage Key for the data load for this row';

-- =============================================
-- Fact.Transaction - Financial transaction fact table (partitioned by date_key)
-- =============================================
CREATE TABLE fact.transaction (
    transaction_key bigserial NOT NULL,
    date_key date NOT NULL,
    customer_key integer NULL,
    bill_to_customer_key integer NULL,
    supplier_key integer NULL,
    transaction_type_key integer NOT NULL,
    payment_method_key integer NULL,
    wwi_customer_transaction_id integer NULL,
    wwi_supplier_transaction_id integer NULL,
    wwi_invoice_id integer NULL,
    wwi_purchase_order_id integer NULL,
    supplier_invoice_number varchar(20) NULL,
    total_excluding_tax numeric(18,2) NOT NULL,
    tax_amount numeric(18,2) NOT NULL,
    total_including_tax numeric(18,2) NOT NULL,
    outstanding_balance numeric(18,2) NOT NULL,
    is_finalized boolean NOT NULL,
    lineage_key integer NOT NULL,
    CONSTRAINT pk_fact_transaction PRIMARY KEY (transaction_key, date_key)
) PARTITION BY RANGE (date_key);

-- Create partitions for years 2012-2025
CREATE TABLE fact.transaction_2012 PARTITION OF fact.transaction
    FOR VALUES FROM ('2012-01-01') TO ('2013-01-01');
CREATE TABLE fact.transaction_2013 PARTITION OF fact.transaction
    FOR VALUES FROM ('2013-01-01') TO ('2014-01-01');
CREATE TABLE fact.transaction_2014 PARTITION OF fact.transaction
    FOR VALUES FROM ('2014-01-01') TO ('2015-01-01');
CREATE TABLE fact.transaction_2015 PARTITION OF fact.transaction
    FOR VALUES FROM ('2015-01-01') TO ('2016-01-01');
CREATE TABLE fact.transaction_2016 PARTITION OF fact.transaction
    FOR VALUES FROM ('2016-01-01') TO ('2017-01-01');
CREATE TABLE fact.transaction_2017 PARTITION OF fact.transaction
    FOR VALUES FROM ('2017-01-01') TO ('2018-01-01');
CREATE TABLE fact.transaction_2018 PARTITION OF fact.transaction
    FOR VALUES FROM ('2018-01-01') TO ('2019-01-01');
CREATE TABLE fact.transaction_2019 PARTITION OF fact.transaction
    FOR VALUES FROM ('2019-01-01') TO ('2020-01-01');
CREATE TABLE fact.transaction_2020 PARTITION OF fact.transaction
    FOR VALUES FROM ('2020-01-01') TO ('2021-01-01');
CREATE TABLE fact.transaction_2021 PARTITION OF fact.transaction
    FOR VALUES FROM ('2021-01-01') TO ('2022-01-01');
CREATE TABLE fact.transaction_2022 PARTITION OF fact.transaction
    FOR VALUES FROM ('2022-01-01') TO ('2023-01-01');
CREATE TABLE fact.transaction_2023 PARTITION OF fact.transaction
    FOR VALUES FROM ('2023-01-01') TO ('2024-01-01');
CREATE TABLE fact.transaction_2024 PARTITION OF fact.transaction
    FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');
CREATE TABLE fact.transaction_2025 PARTITION OF fact.transaction
    FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');

COMMENT ON TABLE fact.transaction IS 'Transaction fact';
COMMENT ON COLUMN fact.transaction.transaction_key IS 'DW key for a row in the Transaction fact';
COMMENT ON COLUMN fact.transaction.date_key IS 'Transaction date';
COMMENT ON COLUMN fact.transaction.customer_key IS 'Customer (if applicable)';
COMMENT ON COLUMN fact.transaction.bill_to_customer_key IS 'Bill to customer (if applicable)';
COMMENT ON COLUMN fact.transaction.supplier_key IS 'Supplier (if applicable)';
COMMENT ON COLUMN fact.transaction.transaction_type_key IS 'Transaction type';
COMMENT ON COLUMN fact.transaction.payment_method_key IS 'Payment method (if applicable)';
COMMENT ON COLUMN fact.transaction.wwi_customer_transaction_id IS 'CustomerTransactionID in source system';
COMMENT ON COLUMN fact.transaction.wwi_supplier_transaction_id IS 'SupplierTransactionID in source system';
COMMENT ON COLUMN fact.transaction.wwi_invoice_id IS 'InvoiceID in source system';
COMMENT ON COLUMN fact.transaction.wwi_purchase_order_id IS 'PurchaseOrderID in source system';
COMMENT ON COLUMN fact.transaction.supplier_invoice_number IS 'Supplier invoice number';
COMMENT ON COLUMN fact.transaction.total_excluding_tax IS 'Total excluding tax';
COMMENT ON COLUMN fact.transaction.tax_amount IS 'Tax amount';
COMMENT ON COLUMN fact.transaction.total_including_tax IS 'Total including tax';
COMMENT ON COLUMN fact.transaction.outstanding_balance IS 'Outstanding balance after this transaction';
COMMENT ON COLUMN fact.transaction.is_finalized IS 'Has this transaction been finalized?';
COMMENT ON COLUMN fact.transaction.lineage_key IS 'Lineage Key for the data load for this row';

-- =============================================
-- Fact.Stock_Holding - Stock holding fact table (non-partitioned)
-- =============================================
CREATE TABLE fact.stock_holding (
    stock_holding_key bigserial NOT NULL,
    stock_item_key integer NOT NULL,
    quantity_on_hand integer NOT NULL,
    bin_location varchar(20) NOT NULL,
    last_stocktake_quantity integer NOT NULL,
    last_cost_price numeric(18,2) NOT NULL,
    reorder_level integer NOT NULL,
    target_stock_level integer NOT NULL,
    lineage_key integer NOT NULL,
    CONSTRAINT pk_fact_stock_holding PRIMARY KEY (stock_holding_key)
);

COMMENT ON TABLE fact.stock_holding IS 'Stock Holding fact';
COMMENT ON COLUMN fact.stock_holding.stock_holding_key IS 'DW key for a row in the Stock Holding fact';
COMMENT ON COLUMN fact.stock_holding.stock_item_key IS 'Stock item being held';
COMMENT ON COLUMN fact.stock_holding.quantity_on_hand IS 'Quantity currently on hand (if tracked)';
COMMENT ON COLUMN fact.stock_holding.bin_location IS 'Bin location (where is this stock in the warehouse)';
COMMENT ON COLUMN fact.stock_holding.last_stocktake_quantity IS 'Quantity at last stocktake (if tracked)';
COMMENT ON COLUMN fact.stock_holding.last_cost_price IS 'Unit cost when last purchased';
COMMENT ON COLUMN fact.stock_holding.reorder_level IS 'Quantity below which reordering should take place';
COMMENT ON COLUMN fact.stock_holding.target_stock_level IS 'Typical quantity ordered when reordering';
COMMENT ON COLUMN fact.stock_holding.lineage_key IS 'Lineage Key for the data load for this row';
