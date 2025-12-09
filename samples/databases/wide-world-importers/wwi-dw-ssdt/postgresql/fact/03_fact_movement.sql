-- Wide World Importers Data Warehouse - PostgreSQL Schema Migration
-- Phase 4: OLAP Schema Migration
-- Fact: Movement
-- Note: Uses PostgreSQL native range partitioning by date_key

-- Create the partitioned fact table
CREATE TABLE fact.movement (
    movement_key                    BIGINT GENERATED ALWAYS AS IDENTITY,
    date_key                        DATE NOT NULL,
    stock_item_key                  INTEGER NOT NULL,
    customer_key                    INTEGER,
    supplier_key                    INTEGER,
    transaction_type_key            INTEGER NOT NULL,
    wwi_stock_item_transaction_id   INTEGER NOT NULL,
    wwi_invoice_id                  INTEGER,
    wwi_purchase_order_id           INTEGER,
    quantity                        INTEGER NOT NULL,
    lineage_key                     INTEGER NOT NULL,

    CONSTRAINT pk_fact_movement PRIMARY KEY (movement_key, date_key)
) PARTITION BY RANGE (date_key);

-- Create partitions for each year (matching SQL Server partition scheme)
CREATE TABLE fact.movement_y2012 PARTITION OF fact.movement
    FOR VALUES FROM ('2012-01-01') TO ('2013-01-01');

CREATE TABLE fact.movement_y2013 PARTITION OF fact.movement
    FOR VALUES FROM ('2013-01-01') TO ('2014-01-01');

CREATE TABLE fact.movement_y2014 PARTITION OF fact.movement
    FOR VALUES FROM ('2014-01-01') TO ('2015-01-01');

CREATE TABLE fact.movement_y2015 PARTITION OF fact.movement
    FOR VALUES FROM ('2015-01-01') TO ('2016-01-01');

CREATE TABLE fact.movement_y2016 PARTITION OF fact.movement
    FOR VALUES FROM ('2016-01-01') TO ('2017-01-01');

CREATE TABLE fact.movement_y2017 PARTITION OF fact.movement
    FOR VALUES FROM ('2017-01-01') TO ('2018-01-01');

-- Default partition for dates outside the defined ranges
CREATE TABLE fact.movement_default PARTITION OF fact.movement DEFAULT;

-- Create indexes on the partitioned table
CREATE INDEX ix_fact_movement_date_key ON fact.movement (date_key);
CREATE INDEX ix_fact_movement_stock_item_key ON fact.movement (stock_item_key);
CREATE INDEX ix_fact_movement_customer_key ON fact.movement (customer_key);
CREATE INDEX ix_fact_movement_supplier_key ON fact.movement (supplier_key);
CREATE INDEX ix_fact_movement_transaction_type_key ON fact.movement (transaction_type_key);
CREATE INDEX ix_fact_movement_wwi_stock_item_transaction_id ON fact.movement (wwi_stock_item_transaction_id);

-- Add foreign key constraints
ALTER TABLE fact.movement ADD CONSTRAINT fk_fact_movement_date_key
    FOREIGN KEY (date_key) REFERENCES dimension.date (date);

ALTER TABLE fact.movement ADD CONSTRAINT fk_fact_movement_stock_item_key
    FOREIGN KEY (stock_item_key) REFERENCES dimension.stock_item (stock_item_key);

ALTER TABLE fact.movement ADD CONSTRAINT fk_fact_movement_customer_key
    FOREIGN KEY (customer_key) REFERENCES dimension.customer (customer_key);

ALTER TABLE fact.movement ADD CONSTRAINT fk_fact_movement_supplier_key
    FOREIGN KEY (supplier_key) REFERENCES dimension.supplier (supplier_key);

ALTER TABLE fact.movement ADD CONSTRAINT fk_fact_movement_transaction_type_key
    FOREIGN KEY (transaction_type_key) REFERENCES dimension.transaction_type (transaction_type_key);

-- Add table and column comments
COMMENT ON TABLE fact.movement IS 'Movement fact table (movements of stock items)';
COMMENT ON COLUMN fact.movement.movement_key IS 'DW key for a row in the Movement fact';
COMMENT ON COLUMN fact.movement.date_key IS 'Transaction date';
COMMENT ON COLUMN fact.movement.stock_item_key IS 'Stock item for this purchase order';
COMMENT ON COLUMN fact.movement.customer_key IS 'Customer (if applicable)';
COMMENT ON COLUMN fact.movement.supplier_key IS 'Supplier (if applicable)';
COMMENT ON COLUMN fact.movement.transaction_type_key IS 'Type of transaction';
COMMENT ON COLUMN fact.movement.wwi_stock_item_transaction_id IS 'Stock item transaction ID in source system';
COMMENT ON COLUMN fact.movement.wwi_invoice_id IS 'Invoice ID in source system';
COMMENT ON COLUMN fact.movement.wwi_purchase_order_id IS 'Purchase order ID in source system';
COMMENT ON COLUMN fact.movement.quantity IS 'Quantity of stock movement (positive is incoming stock, negative is outgoing)';
COMMENT ON COLUMN fact.movement.lineage_key IS 'Lineage Key for the data load for this row';
