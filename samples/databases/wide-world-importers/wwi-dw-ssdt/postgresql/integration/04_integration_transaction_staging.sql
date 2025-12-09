-- Wide World Importers Data Warehouse - PostgreSQL Schema Migration
-- Phase 4: OLAP Schema Migration
-- Integration: Transaction Staging table
-- Note: SQL Server memory-optimized tables are converted to UNLOGGED tables

CREATE UNLOGGED TABLE integration.transaction_staging (
    transaction_staging_key         BIGINT GENERATED ALWAYS AS IDENTITY,
    date_key                        DATE,
    customer_key                    INTEGER,
    bill_to_customer_key            INTEGER,
    supplier_key                    INTEGER,
    transaction_type_key            INTEGER,
    payment_method_key              INTEGER,
    wwi_customer_transaction_id     INTEGER,
    wwi_supplier_transaction_id     INTEGER,
    wwi_invoice_id                  INTEGER,
    wwi_purchase_order_id           INTEGER,
    supplier_invoice_number         VARCHAR(20),
    total_excluding_tax             DECIMAL(18, 2),
    tax_amount                      DECIMAL(18, 2),
    total_including_tax             DECIMAL(18, 2),
    outstanding_balance             DECIMAL(18, 2),
    is_finalized                    BOOLEAN,
    wwi_customer_id                 INTEGER,
    wwi_bill_to_customer_id         INTEGER,
    wwi_supplier_id                 INTEGER,
    wwi_transaction_type_id         INTEGER,
    wwi_payment_method_id           INTEGER,
    last_modified_when              TIMESTAMP,

    CONSTRAINT pk_integration_transaction_staging PRIMARY KEY (transaction_staging_key)
);

COMMENT ON TABLE integration.transaction_staging IS 'Transaction staging table (UNLOGGED for ETL performance)';
