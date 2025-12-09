-- Wide World Importers Data Warehouse - PostgreSQL Schema Migration
-- Phase 4: OLAP Schema Migration
-- Fact: Transaction
-- Note: Uses PostgreSQL native range partitioning by date_key

-- Create the partitioned fact table
CREATE TABLE fact.transaction (
    transaction_key                 BIGINT GENERATED ALWAYS AS IDENTITY,
    date_key                        DATE NOT NULL,
    customer_key                    INTEGER,
    bill_to_customer_key            INTEGER,
    supplier_key                    INTEGER,
    transaction_type_key            INTEGER NOT NULL,
    payment_method_key              INTEGER,
    wwi_customer_transaction_id     INTEGER,
    wwi_supplier_transaction_id     INTEGER,
    wwi_invoice_id                  INTEGER,
    wwi_purchase_order_id           INTEGER,
    supplier_invoice_number         VARCHAR(20),
    total_excluding_tax             DECIMAL(18, 2) NOT NULL,
    tax_amount                      DECIMAL(18, 2) NOT NULL,
    total_including_tax             DECIMAL(18, 2) NOT NULL,
    outstanding_balance             DECIMAL(18, 2) NOT NULL,
    is_finalized                    BOOLEAN NOT NULL,
    lineage_key                     INTEGER NOT NULL,

    CONSTRAINT pk_fact_transaction PRIMARY KEY (transaction_key, date_key)
) PARTITION BY RANGE (date_key);

-- Create partitions for each year (matching SQL Server partition scheme)
CREATE TABLE fact.transaction_y2012 PARTITION OF fact.transaction
    FOR VALUES FROM ('2012-01-01') TO ('2013-01-01');

CREATE TABLE fact.transaction_y2013 PARTITION OF fact.transaction
    FOR VALUES FROM ('2013-01-01') TO ('2014-01-01');

CREATE TABLE fact.transaction_y2014 PARTITION OF fact.transaction
    FOR VALUES FROM ('2014-01-01') TO ('2015-01-01');

CREATE TABLE fact.transaction_y2015 PARTITION OF fact.transaction
    FOR VALUES FROM ('2015-01-01') TO ('2016-01-01');

CREATE TABLE fact.transaction_y2016 PARTITION OF fact.transaction
    FOR VALUES FROM ('2016-01-01') TO ('2017-01-01');

CREATE TABLE fact.transaction_y2017 PARTITION OF fact.transaction
    FOR VALUES FROM ('2017-01-01') TO ('2018-01-01');

-- Default partition for dates outside the defined ranges
CREATE TABLE fact.transaction_default PARTITION OF fact.transaction DEFAULT;

-- Create indexes on the partitioned table
CREATE INDEX ix_fact_transaction_date_key ON fact.transaction (date_key);
CREATE INDEX ix_fact_transaction_customer_key ON fact.transaction (customer_key);
CREATE INDEX ix_fact_transaction_bill_to_customer_key ON fact.transaction (bill_to_customer_key);
CREATE INDEX ix_fact_transaction_supplier_key ON fact.transaction (supplier_key);
CREATE INDEX ix_fact_transaction_transaction_type_key ON fact.transaction (transaction_type_key);
CREATE INDEX ix_fact_transaction_payment_method_key ON fact.transaction (payment_method_key);

-- Add foreign key constraints
ALTER TABLE fact.transaction ADD CONSTRAINT fk_fact_transaction_date_key
    FOREIGN KEY (date_key) REFERENCES dimension.date (date);

ALTER TABLE fact.transaction ADD CONSTRAINT fk_fact_transaction_customer_key
    FOREIGN KEY (customer_key) REFERENCES dimension.customer (customer_key);

ALTER TABLE fact.transaction ADD CONSTRAINT fk_fact_transaction_bill_to_customer_key
    FOREIGN KEY (bill_to_customer_key) REFERENCES dimension.customer (customer_key);

ALTER TABLE fact.transaction ADD CONSTRAINT fk_fact_transaction_supplier_key
    FOREIGN KEY (supplier_key) REFERENCES dimension.supplier (supplier_key);

ALTER TABLE fact.transaction ADD CONSTRAINT fk_fact_transaction_transaction_type_key
    FOREIGN KEY (transaction_type_key) REFERENCES dimension.transaction_type (transaction_type_key);

ALTER TABLE fact.transaction ADD CONSTRAINT fk_fact_transaction_payment_method_key
    FOREIGN KEY (payment_method_key) REFERENCES dimension.payment_method (payment_method_key);

-- Add table and column comments
COMMENT ON TABLE fact.transaction IS 'Transaction fact table (financial transactions involving customers and suppliers)';
COMMENT ON COLUMN fact.transaction.transaction_key IS 'DW key for a row in the Transaction fact';
COMMENT ON COLUMN fact.transaction.date_key IS 'Transaction date';
COMMENT ON COLUMN fact.transaction.customer_key IS 'Customer (if applicable)';
COMMENT ON COLUMN fact.transaction.bill_to_customer_key IS 'Bill to customer (if applicable)';
COMMENT ON COLUMN fact.transaction.supplier_key IS 'Supplier (if applicable)';
COMMENT ON COLUMN fact.transaction.transaction_type_key IS 'Type of transaction';
COMMENT ON COLUMN fact.transaction.payment_method_key IS 'Payment method (if applicable)';
COMMENT ON COLUMN fact.transaction.wwi_customer_transaction_id IS 'Customer transaction ID in source system';
COMMENT ON COLUMN fact.transaction.wwi_supplier_transaction_id IS 'Supplier transaction ID in source system';
COMMENT ON COLUMN fact.transaction.wwi_invoice_id IS 'Invoice ID in source system';
COMMENT ON COLUMN fact.transaction.wwi_purchase_order_id IS 'Purchase order ID in source system';
COMMENT ON COLUMN fact.transaction.supplier_invoice_number IS 'Supplier invoice number (if applicable)';
COMMENT ON COLUMN fact.transaction.total_excluding_tax IS 'Total amount excluding tax';
COMMENT ON COLUMN fact.transaction.tax_amount IS 'Total amount of tax';
COMMENT ON COLUMN fact.transaction.total_including_tax IS 'Total amount including tax';
COMMENT ON COLUMN fact.transaction.outstanding_balance IS 'Amount still outstanding for this transaction';
COMMENT ON COLUMN fact.transaction.is_finalized IS 'Has this transaction been finalized?';
COMMENT ON COLUMN fact.transaction.lineage_key IS 'Lineage Key for the data load for this row';
