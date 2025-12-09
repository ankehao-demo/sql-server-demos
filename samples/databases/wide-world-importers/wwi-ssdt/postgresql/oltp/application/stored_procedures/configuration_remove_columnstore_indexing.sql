-- PostgreSQL equivalent of [Application].Configuration_RemoveColumnstoreIndexing
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE PROCEDURE application.configuration_remove_columnstore_indexing()
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    BEGIN
        -- Remove BRIN indexes created as columnstore alternatives
        
        DROP INDEX IF EXISTS sales.brin_sales_order_lines;
        RAISE NOTICE 'Dropped BRIN index on Sales.OrderLines';
        
        DROP INDEX IF EXISTS sales.brin_sales_invoice_lines;
        RAISE NOTICE 'Dropped BRIN index on Sales.InvoiceLines';
        
        DROP INDEX IF EXISTS warehouse.brin_stock_item_transactions;
        RAISE NOTICE 'Dropped BRIN index on Warehouse.StockItemTransactions';
        
        RAISE NOTICE 'Successfully removed BRIN indexing';
        
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Unable to remove columnstore/BRIN indexing: %', SQLERRM;
        RAISE;
    END;
END;
$$;

COMMENT ON PROCEDURE application.configuration_remove_columnstore_indexing IS 'Removes BRIN indexes (PostgreSQL alternative to SQL Server columnstore indexes)';
