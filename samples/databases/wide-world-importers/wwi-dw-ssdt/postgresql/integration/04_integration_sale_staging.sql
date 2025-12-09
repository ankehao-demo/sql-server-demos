-- Wide World Importers Data Warehouse - PostgreSQL Schema Migration
-- Phase 4: OLAP Schema Migration
-- Integration: Sale Staging table
-- Note: SQL Server memory-optimized tables are converted to UNLOGGED tables

CREATE UNLOGGED TABLE integration.sale_staging (
    sale_staging_key        BIGINT GENERATED ALWAYS AS IDENTITY,
    city_key                INTEGER,
    customer_key            INTEGER,
    bill_to_customer_key    INTEGER,
    stock_item_key          INTEGER,
    invoice_date_key        DATE,
    delivery_date_key       DATE,
    salesperson_key         INTEGER,
    wwi_invoice_id          INTEGER,
    description             VARCHAR(100),
    package                 VARCHAR(50),
    quantity                INTEGER,
    unit_price              DECIMAL(18, 2),
    tax_rate                DECIMAL(18, 3),
    total_excluding_tax     DECIMAL(18, 2),
    tax_amount              DECIMAL(18, 2),
    profit                  DECIMAL(18, 2),
    total_including_tax     DECIMAL(18, 2),
    total_dry_items         INTEGER,
    total_chiller_items     INTEGER,
    wwi_city_id             INTEGER,
    wwi_customer_id         INTEGER,
    wwi_bill_to_customer_id INTEGER,
    wwi_stock_item_id       INTEGER,
    wwi_salesperson_id      INTEGER,
    last_modified_when      TIMESTAMP,

    CONSTRAINT pk_integration_sale_staging PRIMARY KEY (sale_staging_key)
);

COMMENT ON TABLE integration.sale_staging IS 'Sale staging table (UNLOGGED for ETL performance)';
