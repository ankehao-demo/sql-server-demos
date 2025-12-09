-- Wide World Importers Data Warehouse - PostgreSQL Schema Migration
-- Phase 4: OLAP Schema Migration
-- Fact: Sale
-- Note: Uses PostgreSQL native range partitioning by invoice_date_key
-- Note: SQL Server clustered columnstore index is not directly available in PostgreSQL
--       Consider using columnar storage extensions like Citus or TimescaleDB for similar functionality

-- Create the partitioned fact table
CREATE TABLE fact.sale (
    sale_key                BIGINT GENERATED ALWAYS AS IDENTITY,
    city_key                INTEGER NOT NULL,
    customer_key            INTEGER NOT NULL,
    bill_to_customer_key    INTEGER NOT NULL,
    stock_item_key          INTEGER NOT NULL,
    invoice_date_key        DATE NOT NULL,
    delivery_date_key       DATE,
    salesperson_key         INTEGER NOT NULL,
    wwi_invoice_id          INTEGER NOT NULL,
    description             VARCHAR(100) NOT NULL,
    package                 VARCHAR(50) NOT NULL,
    quantity                INTEGER NOT NULL,
    unit_price              DECIMAL(18, 2) NOT NULL,
    tax_rate                DECIMAL(18, 3) NOT NULL,
    total_excluding_tax     DECIMAL(18, 2) NOT NULL,
    tax_amount              DECIMAL(18, 2) NOT NULL,
    profit                  DECIMAL(18, 2) NOT NULL,
    total_including_tax     DECIMAL(18, 2) NOT NULL,
    total_dry_items         INTEGER NOT NULL,
    total_chiller_items     INTEGER NOT NULL,
    lineage_key             INTEGER NOT NULL,

    CONSTRAINT pk_fact_sale PRIMARY KEY (sale_key, invoice_date_key)
) PARTITION BY RANGE (invoice_date_key);

-- Create partitions for each year (matching SQL Server partition scheme)
CREATE TABLE fact.sale_y2012 PARTITION OF fact.sale
    FOR VALUES FROM ('2012-01-01') TO ('2013-01-01');

CREATE TABLE fact.sale_y2013 PARTITION OF fact.sale
    FOR VALUES FROM ('2013-01-01') TO ('2014-01-01');

CREATE TABLE fact.sale_y2014 PARTITION OF fact.sale
    FOR VALUES FROM ('2014-01-01') TO ('2015-01-01');

CREATE TABLE fact.sale_y2015 PARTITION OF fact.sale
    FOR VALUES FROM ('2015-01-01') TO ('2016-01-01');

CREATE TABLE fact.sale_y2016 PARTITION OF fact.sale
    FOR VALUES FROM ('2016-01-01') TO ('2017-01-01');

CREATE TABLE fact.sale_y2017 PARTITION OF fact.sale
    FOR VALUES FROM ('2017-01-01') TO ('2018-01-01');

-- Default partition for dates outside the defined ranges
CREATE TABLE fact.sale_default PARTITION OF fact.sale DEFAULT;

-- Create indexes on the partitioned table (will be created on each partition)
CREATE INDEX ix_fact_sale_city_key ON fact.sale (city_key);
CREATE INDEX ix_fact_sale_customer_key ON fact.sale (customer_key);
CREATE INDEX ix_fact_sale_bill_to_customer_key ON fact.sale (bill_to_customer_key);
CREATE INDEX ix_fact_sale_stock_item_key ON fact.sale (stock_item_key);
CREATE INDEX ix_fact_sale_invoice_date_key ON fact.sale (invoice_date_key);
CREATE INDEX ix_fact_sale_delivery_date_key ON fact.sale (delivery_date_key);
CREATE INDEX ix_fact_sale_salesperson_key ON fact.sale (salesperson_key);

-- Add foreign key constraints
-- Note: Foreign keys on partitioned tables require the partition key to be included
ALTER TABLE fact.sale ADD CONSTRAINT fk_fact_sale_city_key
    FOREIGN KEY (city_key) REFERENCES dimension.city (city_key);

ALTER TABLE fact.sale ADD CONSTRAINT fk_fact_sale_customer_key
    FOREIGN KEY (customer_key) REFERENCES dimension.customer (customer_key);

ALTER TABLE fact.sale ADD CONSTRAINT fk_fact_sale_bill_to_customer_key
    FOREIGN KEY (bill_to_customer_key) REFERENCES dimension.customer (customer_key);

ALTER TABLE fact.sale ADD CONSTRAINT fk_fact_sale_stock_item_key
    FOREIGN KEY (stock_item_key) REFERENCES dimension.stock_item (stock_item_key);

ALTER TABLE fact.sale ADD CONSTRAINT fk_fact_sale_invoice_date_key
    FOREIGN KEY (invoice_date_key) REFERENCES dimension.date (date);

ALTER TABLE fact.sale ADD CONSTRAINT fk_fact_sale_delivery_date_key
    FOREIGN KEY (delivery_date_key) REFERENCES dimension.date (date);

ALTER TABLE fact.sale ADD CONSTRAINT fk_fact_sale_salesperson_key
    FOREIGN KEY (salesperson_key) REFERENCES dimension.employee (employee_key);

-- Add table and column comments
COMMENT ON TABLE fact.sale IS 'Sale fact table (invoiced sales to customers)';
COMMENT ON COLUMN fact.sale.sale_key IS 'DW key for a row in the Sale fact';
COMMENT ON COLUMN fact.sale.city_key IS 'City for this invoice';
COMMENT ON COLUMN fact.sale.customer_key IS 'Customer for this invoice';
COMMENT ON COLUMN fact.sale.bill_to_customer_key IS 'Bill To Customer for this invoice';
COMMENT ON COLUMN fact.sale.stock_item_key IS 'Stock item for this invoice';
COMMENT ON COLUMN fact.sale.invoice_date_key IS 'Invoice date for this invoice';
COMMENT ON COLUMN fact.sale.delivery_date_key IS 'Date that these items were delivered';
COMMENT ON COLUMN fact.sale.salesperson_key IS 'Salesperson for this invoice';
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
