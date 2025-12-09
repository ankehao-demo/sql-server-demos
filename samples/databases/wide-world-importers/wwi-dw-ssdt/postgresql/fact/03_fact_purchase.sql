-- Wide World Importers Data Warehouse - PostgreSQL Schema Migration
-- Phase 4: OLAP Schema Migration
-- Fact: Purchase
-- Note: Uses PostgreSQL native range partitioning by date_key

-- Create the partitioned fact table
CREATE TABLE fact.purchase (
    purchase_key            BIGINT GENERATED ALWAYS AS IDENTITY,
    date_key                DATE NOT NULL,
    supplier_key            INTEGER NOT NULL,
    stock_item_key          INTEGER NOT NULL,
    wwi_purchase_order_id   INTEGER,
    ordered_outers          INTEGER NOT NULL,
    ordered_quantity        INTEGER NOT NULL,
    received_outers         INTEGER NOT NULL,
    package                 VARCHAR(50) NOT NULL,
    is_order_finalized      BOOLEAN NOT NULL,
    lineage_key             INTEGER NOT NULL,

    CONSTRAINT pk_fact_purchase PRIMARY KEY (purchase_key, date_key)
) PARTITION BY RANGE (date_key);

-- Create partitions for each year (matching SQL Server partition scheme)
CREATE TABLE fact.purchase_y2012 PARTITION OF fact.purchase
    FOR VALUES FROM ('2012-01-01') TO ('2013-01-01');

CREATE TABLE fact.purchase_y2013 PARTITION OF fact.purchase
    FOR VALUES FROM ('2013-01-01') TO ('2014-01-01');

CREATE TABLE fact.purchase_y2014 PARTITION OF fact.purchase
    FOR VALUES FROM ('2014-01-01') TO ('2015-01-01');

CREATE TABLE fact.purchase_y2015 PARTITION OF fact.purchase
    FOR VALUES FROM ('2015-01-01') TO ('2016-01-01');

CREATE TABLE fact.purchase_y2016 PARTITION OF fact.purchase
    FOR VALUES FROM ('2016-01-01') TO ('2017-01-01');

CREATE TABLE fact.purchase_y2017 PARTITION OF fact.purchase
    FOR VALUES FROM ('2017-01-01') TO ('2018-01-01');

-- Default partition for dates outside the defined ranges
CREATE TABLE fact.purchase_default PARTITION OF fact.purchase DEFAULT;

-- Create indexes on the partitioned table
CREATE INDEX ix_fact_purchase_date_key ON fact.purchase (date_key);
CREATE INDEX ix_fact_purchase_supplier_key ON fact.purchase (supplier_key);
CREATE INDEX ix_fact_purchase_stock_item_key ON fact.purchase (stock_item_key);

-- Add foreign key constraints
ALTER TABLE fact.purchase ADD CONSTRAINT fk_fact_purchase_date_key
    FOREIGN KEY (date_key) REFERENCES dimension.date (date);

ALTER TABLE fact.purchase ADD CONSTRAINT fk_fact_purchase_supplier_key
    FOREIGN KEY (supplier_key) REFERENCES dimension.supplier (supplier_key);

ALTER TABLE fact.purchase ADD CONSTRAINT fk_fact_purchase_stock_item_key
    FOREIGN KEY (stock_item_key) REFERENCES dimension.stock_item (stock_item_key);

-- Add table and column comments
COMMENT ON TABLE fact.purchase IS 'Purchase fact table (stock purchases from suppliers)';
COMMENT ON COLUMN fact.purchase.purchase_key IS 'DW key for a row in the Purchase fact';
COMMENT ON COLUMN fact.purchase.date_key IS 'Purchase order date';
COMMENT ON COLUMN fact.purchase.supplier_key IS 'Supplier for this purchase order';
COMMENT ON COLUMN fact.purchase.stock_item_key IS 'Stock item for this purchase order';
COMMENT ON COLUMN fact.purchase.wwi_purchase_order_id IS 'Purchase order ID in source system';
COMMENT ON COLUMN fact.purchase.ordered_outers IS 'Quantity of outers (ordering packages)';
COMMENT ON COLUMN fact.purchase.ordered_quantity IS 'Quantity of inners (selling packages)';
COMMENT ON COLUMN fact.purchase.received_outers IS 'Received outers (so far)';
COMMENT ON COLUMN fact.purchase.package IS 'Package ordered';
COMMENT ON COLUMN fact.purchase.is_order_finalized IS 'Is this purchase order now finalized?';
COMMENT ON COLUMN fact.purchase.lineage_key IS 'Lineage Key for the data load for this row';
