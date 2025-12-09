-- PostgreSQL equivalent of [Application].Configuration_ApplyColumnstoreIndexing
-- Converted from T-SQL to PL/pgSQL
-- Note: PostgreSQL does not have native columnstore indexes like SQL Server
-- This procedure creates BRIN indexes as an alternative for analytical workloads
-- For true columnar storage, consider using Citus columnar or TimescaleDB

CREATE OR REPLACE PROCEDURE application.configuration_apply_columnstore_indexing()
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    BEGIN
        RAISE NOTICE 'PostgreSQL does not have native columnstore indexes.';
        RAISE NOTICE 'Creating BRIN indexes as an alternative for analytical workloads.';
        RAISE NOTICE 'For true columnar storage, consider Citus columnar extension or TimescaleDB.';
        
        -- Create BRIN indexes on large tables for analytical queries
        -- BRIN indexes are efficient for large tables with naturally ordered data
        
        -- Sales.OrderLines - BRIN index for analytical queries
        IF NOT EXISTS (
            SELECT 1 FROM pg_indexes 
            WHERE indexname = 'brin_sales_order_lines'
        ) THEN
            CREATE INDEX brin_sales_order_lines 
            ON sales.order_lines 
            USING BRIN (order_id, stock_item_id);
            RAISE NOTICE 'Created BRIN index on Sales.OrderLines';
        END IF;
        
        -- Sales.InvoiceLines - BRIN index for analytical queries
        IF NOT EXISTS (
            SELECT 1 FROM pg_indexes 
            WHERE indexname = 'brin_sales_invoice_lines'
        ) THEN
            CREATE INDEX brin_sales_invoice_lines 
            ON sales.invoice_lines 
            USING BRIN (invoice_id, stock_item_id);
            RAISE NOTICE 'Created BRIN index on Sales.InvoiceLines';
        END IF;
        
        -- Warehouse.StockItemTransactions - BRIN index for time-series queries
        IF NOT EXISTS (
            SELECT 1 FROM pg_indexes 
            WHERE indexname = 'brin_stock_item_transactions'
        ) THEN
            CREATE INDEX brin_stock_item_transactions 
            ON warehouse.stock_item_transactions 
            USING BRIN (transaction_occurred_when);
            RAISE NOTICE 'Created BRIN index on Warehouse.StockItemTransactions';
        END IF;
        
        RAISE NOTICE 'Successfully applied BRIN indexing (PostgreSQL alternative to columnstore)';
        
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Unable to apply columnstore/BRIN indexing: %', SQLERRM;
        RAISE;
    END;
END;
$$;

COMMENT ON PROCEDURE application.configuration_apply_columnstore_indexing IS 'Creates BRIN indexes as PostgreSQL alternative to SQL Server columnstore indexes';
