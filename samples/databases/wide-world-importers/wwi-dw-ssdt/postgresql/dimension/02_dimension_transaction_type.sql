-- Wide World Importers Data Warehouse - PostgreSQL Schema Migration
-- Phase 4: OLAP Schema Migration
-- Dimension: Transaction Type

CREATE TABLE dimension.transaction_type (
    transaction_type_key        INTEGER NOT NULL DEFAULT nextval('sequences.transaction_type_key'),
    wwi_transaction_type_id     INTEGER NOT NULL,
    transaction_type            VARCHAR(50) NOT NULL,
    valid_from                  TIMESTAMP NOT NULL,
    valid_to                    TIMESTAMP NOT NULL,
    lineage_key                 INTEGER NOT NULL,

    CONSTRAINT pk_dimension_transaction_type PRIMARY KEY (transaction_type_key)
);

-- Create index for WWI Transaction Type ID lookups (SCD Type 2 pattern)
CREATE INDEX ix_dimension_transaction_type_wwi_transaction_type_id 
    ON dimension.transaction_type (wwi_transaction_type_id, valid_from, valid_to);

-- Add table and column comments
COMMENT ON TABLE dimension.transaction_type IS 'TransactionType dimension';
COMMENT ON COLUMN dimension.transaction_type.transaction_type_key IS 'DW key for the transaction type dimension';
COMMENT ON COLUMN dimension.transaction_type.wwi_transaction_type_id IS 'Numeric ID used for reference to a transaction type within the WWI database';
COMMENT ON COLUMN dimension.transaction_type.transaction_type IS 'Full name of the transaction type';
COMMENT ON COLUMN dimension.transaction_type.valid_from IS 'Valid from this date and time';
COMMENT ON COLUMN dimension.transaction_type.valid_to IS 'Valid until this date and time';
COMMENT ON COLUMN dimension.transaction_type.lineage_key IS 'Lineage Key for the data load for this row';
COMMENT ON INDEX ix_dimension_transaction_type_wwi_transaction_type_id IS 'Allows quickly locating by WWI ID';
