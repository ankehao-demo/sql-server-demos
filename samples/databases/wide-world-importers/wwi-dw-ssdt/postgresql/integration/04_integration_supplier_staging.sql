-- Wide World Importers Data Warehouse - PostgreSQL Schema Migration
-- Phase 4: OLAP Schema Migration
-- Integration: Supplier Staging table
-- Note: SQL Server memory-optimized tables are converted to UNLOGGED tables

CREATE UNLOGGED TABLE integration.supplier_staging (
    supplier_staging_key    INTEGER GENERATED ALWAYS AS IDENTITY,
    wwi_supplier_id         INTEGER NOT NULL,
    supplier                VARCHAR(100) NOT NULL,
    category                VARCHAR(50) NOT NULL,
    primary_contact         VARCHAR(50) NOT NULL,
    supplier_reference      VARCHAR(20),
    payment_days            INTEGER NOT NULL,
    postal_code             VARCHAR(10) NOT NULL,
    valid_from              TIMESTAMP NOT NULL,
    valid_to                TIMESTAMP NOT NULL,

    CONSTRAINT pk_integration_supplier_staging PRIMARY KEY (supplier_staging_key)
);

COMMENT ON TABLE integration.supplier_staging IS 'Supplier staging table (UNLOGGED for ETL performance)';
