-- Wide World Importers Data Warehouse - PostgreSQL Schema Migration
-- Phase 4: OLAP Schema Migration
-- Integration: Payment Method Staging table
-- Note: SQL Server memory-optimized tables are converted to UNLOGGED tables

CREATE UNLOGGED TABLE integration.payment_method_staging (
    payment_method_staging_key  INTEGER GENERATED ALWAYS AS IDENTITY,
    wwi_payment_method_id       INTEGER NOT NULL,
    payment_method              VARCHAR(50) NOT NULL,
    valid_from                  TIMESTAMP NOT NULL,
    valid_to                    TIMESTAMP NOT NULL,

    CONSTRAINT pk_integration_payment_method_staging PRIMARY KEY (payment_method_staging_key)
);

COMMENT ON TABLE integration.payment_method_staging IS 'Payment Method staging table (UNLOGGED for ETL performance)';
