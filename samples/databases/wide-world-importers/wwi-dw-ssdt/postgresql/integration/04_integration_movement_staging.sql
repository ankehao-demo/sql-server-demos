-- Wide World Importers Data Warehouse - PostgreSQL Schema Migration
-- Phase 4: OLAP Schema Migration
-- Integration: Movement Staging table
-- Note: SQL Server memory-optimized tables are converted to UNLOGGED tables

CREATE UNLOGGED TABLE integration.movement_staging (
    movement_staging_key            BIGINT GENERATED ALWAYS AS IDENTITY,
    date_key                        DATE,
    stock_item_key                  INTEGER,
    customer_key                    INTEGER,
    supplier_key                    INTEGER,
    transaction_type_key            INTEGER,
    wwi_stock_item_transaction_id   INTEGER,
    wwi_invoice_id                  INTEGER,
    wwi_purchase_order_id           INTEGER,
    quantity                        INTEGER,
    wwi_stock_item_id               INTEGER,
    wwi_customer_id                 INTEGER,
    wwi_supplier_id                 INTEGER,
    wwi_transaction_type_id         INTEGER,
    last_modified_when              TIMESTAMP,

    CONSTRAINT pk_integration_movement_staging PRIMARY KEY (movement_staging_key)
);

COMMENT ON TABLE integration.movement_staging IS 'Movement staging table (UNLOGGED for ETL performance)';
