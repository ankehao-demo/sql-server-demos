-- Wide World Importers Data Warehouse - PostgreSQL Schema Migration
-- Phase 4: OLAP Schema Migration
-- Integration: Employee Staging table
-- Note: SQL Server memory-optimized tables are converted to UNLOGGED tables

CREATE UNLOGGED TABLE integration.employee_staging (
    employee_staging_key    INTEGER GENERATED ALWAYS AS IDENTITY,
    wwi_employee_id         INTEGER NOT NULL,
    employee                VARCHAR(50) NOT NULL,
    preferred_name          VARCHAR(50) NOT NULL,
    is_salesperson          BOOLEAN NOT NULL,
    photo                   BYTEA,
    valid_from              TIMESTAMP NOT NULL,
    valid_to                TIMESTAMP NOT NULL,

    CONSTRAINT pk_integration_employee_staging PRIMARY KEY (employee_staging_key)
);

COMMENT ON TABLE integration.employee_staging IS 'Employee staging table (UNLOGGED for ETL performance)';
