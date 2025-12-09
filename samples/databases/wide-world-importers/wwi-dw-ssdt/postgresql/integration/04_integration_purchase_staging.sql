-- Wide World Importers Data Warehouse - PostgreSQL Schema Migration
-- Phase 4: OLAP Schema Migration
-- Integration: Purchase Staging table
-- Note: SQL Server memory-optimized tables are converted to UNLOGGED tables

CREATE UNLOGGED TABLE integration.purchase_staging (
    purchase_staging_key    BIGINT GENERATED ALWAYS AS IDENTITY,
    date_key                DATE,
    supplier_key            INTEGER,
    stock_item_key          INTEGER,
    wwi_purchase_order_id   INTEGER,
    ordered_outers          INTEGER,
    ordered_quantity        INTEGER,
    received_outers         INTEGER,
    package                 VARCHAR(50),
    is_order_finalized      BOOLEAN,
    wwi_supplier_id         INTEGER,
    wwi_stock_item_id       INTEGER,
    last_modified_when      TIMESTAMP,

    CONSTRAINT pk_integration_purchase_staging PRIMARY KEY (purchase_staging_key)
);

COMMENT ON TABLE integration.purchase_staging IS 'Purchase staging table (UNLOGGED for ETL performance)';
