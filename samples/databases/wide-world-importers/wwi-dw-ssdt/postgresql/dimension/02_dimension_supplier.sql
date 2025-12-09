-- Wide World Importers Data Warehouse - PostgreSQL Schema Migration
-- Phase 4: OLAP Schema Migration
-- Dimension: Supplier

CREATE TABLE dimension.supplier (
    supplier_key        INTEGER NOT NULL DEFAULT nextval('sequences.supplier_key'),
    wwi_supplier_id     INTEGER NOT NULL,
    supplier            VARCHAR(100) NOT NULL,
    category            VARCHAR(50) NOT NULL,
    primary_contact     VARCHAR(50) NOT NULL,
    supplier_reference  VARCHAR(20),
    payment_days        INTEGER NOT NULL,
    postal_code         VARCHAR(10) NOT NULL,
    valid_from          TIMESTAMP NOT NULL,
    valid_to            TIMESTAMP NOT NULL,
    lineage_key         INTEGER NOT NULL,

    CONSTRAINT pk_dimension_supplier PRIMARY KEY (supplier_key)
);

-- Create index for WWI Supplier ID lookups (SCD Type 2 pattern)
CREATE INDEX ix_dimension_supplier_wwi_supplier_id 
    ON dimension.supplier (wwi_supplier_id, valid_from, valid_to);

-- Add table and column comments
COMMENT ON TABLE dimension.supplier IS 'Supplier dimension';
COMMENT ON COLUMN dimension.supplier.supplier_key IS 'DW key for the supplier dimension';
COMMENT ON COLUMN dimension.supplier.wwi_supplier_id IS 'Numeric ID used for reference to a supplier within the WWI database';
COMMENT ON COLUMN dimension.supplier.supplier IS 'Supplier''s full name (usually a trading name)';
COMMENT ON COLUMN dimension.supplier.category IS 'Supplier''s category';
COMMENT ON COLUMN dimension.supplier.primary_contact IS 'Primary contact';
COMMENT ON COLUMN dimension.supplier.supplier_reference IS 'Supplier reference for our organization (might be our account number at the supplier)';
COMMENT ON COLUMN dimension.supplier.payment_days IS 'Number of days for payment of an invoice (ie payment terms)';
COMMENT ON COLUMN dimension.supplier.postal_code IS 'Delivery postal code for the supplier';
COMMENT ON COLUMN dimension.supplier.valid_from IS 'Valid from this date and time';
COMMENT ON COLUMN dimension.supplier.valid_to IS 'Valid until this date and time';
COMMENT ON COLUMN dimension.supplier.lineage_key IS 'Lineage Key for the data load for this row';
COMMENT ON INDEX dimension.ix_dimension_supplier_wwi_supplier_id IS 'Allows quickly locating by WWI ID';
