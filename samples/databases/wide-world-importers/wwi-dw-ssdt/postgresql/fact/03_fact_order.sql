-- Wide World Importers Data Warehouse - PostgreSQL Schema Migration
-- Phase 4: OLAP Schema Migration
-- Fact: Order
-- Note: Uses PostgreSQL native range partitioning by order_date_key

-- Create the partitioned fact table
CREATE TABLE fact.order (
    order_key               BIGINT GENERATED ALWAYS AS IDENTITY,
    city_key                INTEGER NOT NULL,
    customer_key            INTEGER NOT NULL,
    stock_item_key          INTEGER NOT NULL,
    order_date_key          DATE NOT NULL,
    picked_date_key         DATE,
    salesperson_key         INTEGER NOT NULL,
    picker_key              INTEGER,
    wwi_order_id            INTEGER NOT NULL,
    wwi_backorder_id        INTEGER,
    description             VARCHAR(100) NOT NULL,
    package                 VARCHAR(50) NOT NULL,
    quantity                INTEGER NOT NULL,
    unit_price              DECIMAL(18, 2) NOT NULL,
    tax_rate                DECIMAL(18, 3) NOT NULL,
    total_excluding_tax     DECIMAL(18, 2) NOT NULL,
    tax_amount              DECIMAL(18, 2) NOT NULL,
    total_including_tax     DECIMAL(18, 2) NOT NULL,
    lineage_key             INTEGER NOT NULL,

    CONSTRAINT pk_fact_order PRIMARY KEY (order_key, order_date_key)
) PARTITION BY RANGE (order_date_key);

-- Create partitions for each year (matching SQL Server partition scheme)
CREATE TABLE fact.order_y2012 PARTITION OF fact.order
    FOR VALUES FROM ('2012-01-01') TO ('2013-01-01');

CREATE TABLE fact.order_y2013 PARTITION OF fact.order
    FOR VALUES FROM ('2013-01-01') TO ('2014-01-01');

CREATE TABLE fact.order_y2014 PARTITION OF fact.order
    FOR VALUES FROM ('2014-01-01') TO ('2015-01-01');

CREATE TABLE fact.order_y2015 PARTITION OF fact.order
    FOR VALUES FROM ('2015-01-01') TO ('2016-01-01');

CREATE TABLE fact.order_y2016 PARTITION OF fact.order
    FOR VALUES FROM ('2016-01-01') TO ('2017-01-01');

CREATE TABLE fact.order_y2017 PARTITION OF fact.order
    FOR VALUES FROM ('2017-01-01') TO ('2018-01-01');

-- Default partition for dates outside the defined ranges
CREATE TABLE fact.order_default PARTITION OF fact.order DEFAULT;

-- Create indexes on the partitioned table
CREATE INDEX ix_fact_order_city_key ON fact.order (city_key);
CREATE INDEX ix_fact_order_customer_key ON fact.order (customer_key);
CREATE INDEX ix_fact_order_stock_item_key ON fact.order (stock_item_key);
CREATE INDEX ix_fact_order_order_date_key ON fact.order (order_date_key);
CREATE INDEX ix_fact_order_picked_date_key ON fact.order (picked_date_key);
CREATE INDEX ix_fact_order_salesperson_key ON fact.order (salesperson_key);
CREATE INDEX ix_fact_order_picker_key ON fact.order (picker_key);
CREATE INDEX ix_fact_order_wwi_order_id ON fact.order (wwi_order_id);

-- Add foreign key constraints
ALTER TABLE fact.order ADD CONSTRAINT fk_fact_order_city_key
    FOREIGN KEY (city_key) REFERENCES dimension.city (city_key);

ALTER TABLE fact.order ADD CONSTRAINT fk_fact_order_customer_key
    FOREIGN KEY (customer_key) REFERENCES dimension.customer (customer_key);

ALTER TABLE fact.order ADD CONSTRAINT fk_fact_order_stock_item_key
    FOREIGN KEY (stock_item_key) REFERENCES dimension.stock_item (stock_item_key);

ALTER TABLE fact.order ADD CONSTRAINT fk_fact_order_order_date_key
    FOREIGN KEY (order_date_key) REFERENCES dimension.date (date);

ALTER TABLE fact.order ADD CONSTRAINT fk_fact_order_picked_date_key
    FOREIGN KEY (picked_date_key) REFERENCES dimension.date (date);

ALTER TABLE fact.order ADD CONSTRAINT fk_fact_order_salesperson_key
    FOREIGN KEY (salesperson_key) REFERENCES dimension.employee (employee_key);

ALTER TABLE fact.order ADD CONSTRAINT fk_fact_order_picker_key
    FOREIGN KEY (picker_key) REFERENCES dimension.employee (employee_key);

-- Add table and column comments
COMMENT ON TABLE fact.order IS 'Order fact table (customer orders)';
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
COMMENT ON COLUMN fact.order.description IS 'Description of the item supplied (Usually the stock item name but can be overridden)';
COMMENT ON COLUMN fact.order.package IS 'Type of package to be supplied';
COMMENT ON COLUMN fact.order.quantity IS 'Quantity to be supplied';
COMMENT ON COLUMN fact.order.unit_price IS 'Unit price to be charged';
COMMENT ON COLUMN fact.order.tax_rate IS 'Tax rate to be applied';
COMMENT ON COLUMN fact.order.total_excluding_tax IS 'Total amount excluding tax';
COMMENT ON COLUMN fact.order.tax_amount IS 'Total amount of tax';
COMMENT ON COLUMN fact.order.total_including_tax IS 'Total amount including tax';
COMMENT ON COLUMN fact.order.lineage_key IS 'Lineage Key for the data load for this row';
