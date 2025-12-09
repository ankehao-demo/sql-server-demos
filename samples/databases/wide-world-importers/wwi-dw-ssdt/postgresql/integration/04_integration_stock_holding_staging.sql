-- Wide World Importers Data Warehouse - PostgreSQL Schema Migration
-- Phase 4: OLAP Schema Migration
-- Integration: Stock Holding Staging table
-- Note: SQL Server memory-optimized tables are converted to UNLOGGED tables

CREATE UNLOGGED TABLE integration.stock_holding_staging (
    stock_holding_staging_key   BIGINT GENERATED ALWAYS AS IDENTITY,
    stock_item_key              INTEGER,
    quantity_on_hand            INTEGER,
    bin_location                VARCHAR(20),
    last_stocktake_quantity     INTEGER,
    last_cost_price             DECIMAL(18, 2),
    reorder_level               INTEGER,
    target_stock_level          INTEGER,
    wwi_stock_item_id           INTEGER,

    CONSTRAINT pk_integration_stock_holding_staging PRIMARY KEY (stock_holding_staging_key)
);

COMMENT ON TABLE integration.stock_holding_staging IS 'Stock Holding staging table (UNLOGGED for ETL performance)';
