-- Wide World Importers Data Warehouse - PostgreSQL Schema Migration
-- Phase 4: OLAP Schema Migration
-- Dimension: Payment Method

CREATE TABLE dimension.payment_method (
    payment_method_key      INTEGER NOT NULL DEFAULT nextval('sequences.payment_method_key'),
    wwi_payment_method_id   INTEGER NOT NULL,
    payment_method          VARCHAR(50) NOT NULL,
    valid_from              TIMESTAMP NOT NULL,
    valid_to                TIMESTAMP NOT NULL,
    lineage_key             INTEGER NOT NULL,

    CONSTRAINT pk_dimension_payment_method PRIMARY KEY (payment_method_key)
);

-- Create index for WWI Payment Method ID lookups (SCD Type 2 pattern)
CREATE INDEX ix_dimension_payment_method_wwi_payment_method_id 
    ON dimension.payment_method (wwi_payment_method_id, valid_from, valid_to);

-- Add table and column comments
COMMENT ON TABLE dimension.payment_method IS 'PaymentMethod dimension';
COMMENT ON COLUMN dimension.payment_method.payment_method_key IS 'DW key for the payment method dimension';
COMMENT ON COLUMN dimension.payment_method.wwi_payment_method_id IS 'Numeric ID for the payment method in the WWI database';
COMMENT ON COLUMN dimension.payment_method.payment_method IS 'Payment method name';
COMMENT ON COLUMN dimension.payment_method.valid_from IS 'Valid from this date and time';
COMMENT ON COLUMN dimension.payment_method.valid_to IS 'Valid until this date and time';
COMMENT ON COLUMN dimension.payment_method.lineage_key IS 'Lineage Key for the data load for this row';
COMMENT ON INDEX dimension.ix_dimension_payment_method_wwi_payment_method_id IS 'Allows quickly locating by WWI ID';
