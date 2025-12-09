-- Wide World Importers Data Warehouse - PostgreSQL Schema Migration
-- Phase 4: OLAP Schema Migration
-- Integration: Order Staging table
-- Note: SQL Server memory-optimized tables are converted to UNLOGGED tables

CREATE UNLOGGED TABLE integration.order_staging (
    order_staging_key       BIGINT GENERATED ALWAYS AS IDENTITY,
    city_key                INTEGER,
    customer_key            INTEGER,
    stock_item_key          INTEGER,
    order_date_key          DATE,
    picked_date_key         DATE,
    salesperson_key         INTEGER,
    picker_key              INTEGER,
    wwi_order_id            INTEGER,
    wwi_backorder_id        INTEGER,
    description             VARCHAR(100),
    package                 VARCHAR(50),
    quantity                INTEGER,
    unit_price              DECIMAL(18, 2),
    tax_rate                DECIMAL(18, 3),
    total_excluding_tax     DECIMAL(18, 2),
    tax_amount              DECIMAL(18, 2),
    total_including_tax     DECIMAL(18, 2),
    lineage_key             INTEGER,
    wwi_city_id             INTEGER,
    wwi_customer_id         INTEGER,
    wwi_stock_item_id       INTEGER,
    wwi_salesperson_id      INTEGER,
    wwi_picker_id           INTEGER,
    last_modified_when      TIMESTAMP,

    CONSTRAINT pk_integration_order_staging PRIMARY KEY (order_staging_key)
);

COMMENT ON TABLE integration.order_staging IS 'Order staging table (UNLOGGED for ETL performance)';
