-- Wide World Importers Data Warehouse - PostgreSQL Schema Migration
-- Phase 4: OLAP Schema Migration
-- Integration: Transaction Type Staging table
-- Note: SQL Server memory-optimized tables are converted to UNLOGGED tables

CREATE UNLOGGED TABLE integration.transaction_type_staging (
    transaction_type_staging_key    INTEGER GENERATED ALWAYS AS IDENTITY,
    wwi_transaction_type_id         INTEGER NOT NULL,
    transaction_type                VARCHAR(50) NOT NULL,
    valid_from                      TIMESTAMP NOT NULL,
    valid_to                        TIMESTAMP NOT NULL,

    CONSTRAINT pk_integration_transaction_type_staging PRIMARY KEY (transaction_type_staging_key)
);

COMMENT ON TABLE integration.transaction_type_staging IS 'Transaction Type staging table (UNLOGGED for ETL performance)';
