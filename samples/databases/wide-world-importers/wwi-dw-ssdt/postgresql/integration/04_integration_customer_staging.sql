-- Wide World Importers Data Warehouse - PostgreSQL Schema Migration
-- Phase 4: OLAP Schema Migration
-- Integration: Customer Staging table
-- Note: SQL Server memory-optimized tables (MEMORY_OPTIMIZED = ON, DURABILITY = SCHEMA_ONLY)
--       are converted to UNLOGGED tables in PostgreSQL for similar performance characteristics
--       UNLOGGED tables are not crash-safe but provide faster write performance

CREATE UNLOGGED TABLE integration.customer_staging (
    customer_staging_key    INTEGER GENERATED ALWAYS AS IDENTITY,
    wwi_customer_id         INTEGER NOT NULL,
    customer                VARCHAR(100) NOT NULL,
    bill_to_customer        VARCHAR(100) NOT NULL,
    category                VARCHAR(50) NOT NULL,
    buying_group            VARCHAR(50) NOT NULL,
    primary_contact         VARCHAR(50) NOT NULL,
    postal_code             VARCHAR(10) NOT NULL,
    valid_from              TIMESTAMP NOT NULL,
    valid_to                TIMESTAMP NOT NULL,

    CONSTRAINT pk_integration_customer_staging PRIMARY KEY (customer_staging_key)
);

COMMENT ON TABLE integration.customer_staging IS 'Customer staging table (UNLOGGED for ETL performance)';
