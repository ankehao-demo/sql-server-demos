-- Wide World Importers Data Warehouse - PostgreSQL Schema Migration
-- Phase 4: OLAP Schema Migration
-- Dimension: Customer

CREATE TABLE dimension.customer (
    customer_key        INTEGER NOT NULL DEFAULT nextval('sequences.customer_key'),
    wwi_customer_id     INTEGER NOT NULL,
    customer            VARCHAR(100) NOT NULL,
    bill_to_customer    VARCHAR(100) NOT NULL,
    category            VARCHAR(50) NOT NULL,
    buying_group        VARCHAR(50) NOT NULL,
    primary_contact     VARCHAR(50) NOT NULL,
    postal_code         VARCHAR(10) NOT NULL,
    valid_from          TIMESTAMP NOT NULL,
    valid_to            TIMESTAMP NOT NULL,
    lineage_key         INTEGER NOT NULL,

    CONSTRAINT pk_dimension_customer PRIMARY KEY (customer_key)
);

-- Create index for WWI Customer ID lookups (SCD Type 2 pattern)
CREATE INDEX ix_dimension_customer_wwi_customer_id 
    ON dimension.customer (wwi_customer_id, valid_from, valid_to);

-- Add table and column comments
COMMENT ON TABLE dimension.customer IS 'Customer dimension';
COMMENT ON COLUMN dimension.customer.customer_key IS 'DW key for the customer dimension';
COMMENT ON COLUMN dimension.customer.wwi_customer_id IS 'Numeric ID used for reference to a customer within the WWI database';
COMMENT ON COLUMN dimension.customer.customer IS 'Customer''s full name (usually a trading name)';
COMMENT ON COLUMN dimension.customer.bill_to_customer IS 'Bill to customer''s full name';
COMMENT ON COLUMN dimension.customer.category IS 'Customer''s category';
COMMENT ON COLUMN dimension.customer.buying_group IS 'Customer''s buying group';
COMMENT ON COLUMN dimension.customer.primary_contact IS 'Primary contact';
COMMENT ON COLUMN dimension.customer.postal_code IS 'Delivery postal code for the customer';
COMMENT ON COLUMN dimension.customer.valid_from IS 'Valid from this date and time';
COMMENT ON COLUMN dimension.customer.valid_to IS 'Valid until this date and time';
COMMENT ON COLUMN dimension.customer.lineage_key IS 'Lineage Key for the data load for this row';
COMMENT ON INDEX dimension.ix_dimension_customer_wwi_customer_id IS 'Allows quickly locating by WWI ID';
