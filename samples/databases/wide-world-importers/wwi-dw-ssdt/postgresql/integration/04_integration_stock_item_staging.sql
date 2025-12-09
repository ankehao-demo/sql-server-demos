-- Wide World Importers Data Warehouse - PostgreSQL Schema Migration
-- Phase 4: OLAP Schema Migration
-- Integration: Stock Item Staging table
-- Note: SQL Server memory-optimized tables are converted to UNLOGGED tables

CREATE UNLOGGED TABLE integration.stock_item_staging (
    stock_item_staging_key      INTEGER GENERATED ALWAYS AS IDENTITY,
    wwi_stock_item_id           INTEGER NOT NULL,
    stock_item                  VARCHAR(100) NOT NULL,
    color                       VARCHAR(20) NOT NULL,
    selling_package             VARCHAR(50) NOT NULL,
    buying_package              VARCHAR(50) NOT NULL,
    brand                       VARCHAR(50) NOT NULL,
    size                        VARCHAR(20) NOT NULL,
    lead_time_days              INTEGER NOT NULL,
    quantity_per_outer          INTEGER NOT NULL,
    is_chiller_stock            BOOLEAN NOT NULL,
    barcode                     VARCHAR(50),
    tax_rate                    DECIMAL(18, 3) NOT NULL,
    unit_price                  DECIMAL(18, 2) NOT NULL,
    recommended_retail_price    DECIMAL(18, 2),
    typical_weight_per_unit     DECIMAL(18, 3) NOT NULL,
    photo                       BYTEA,
    valid_from                  TIMESTAMP NOT NULL,
    valid_to                    TIMESTAMP NOT NULL,

    CONSTRAINT pk_integration_stock_item_staging PRIMARY KEY (stock_item_staging_key)
);

COMMENT ON TABLE integration.stock_item_staging IS 'Stock Item staging table (UNLOGGED for ETL performance)';
