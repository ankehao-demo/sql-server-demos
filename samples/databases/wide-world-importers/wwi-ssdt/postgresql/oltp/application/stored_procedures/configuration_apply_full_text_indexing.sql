-- PostgreSQL equivalent of [Application].Configuration_ApplyFullTextIndexing
-- Converted from T-SQL to PL/pgSQL
-- Note: PostgreSQL uses built-in full-text search with tsvector/tsquery

CREATE OR REPLACE PROCEDURE application.configuration_apply_full_text_indexing()
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Check if full-text search is available (it's built into PostgreSQL)
    -- No need to check for installation like SQL Server
    
    BEGIN
        -- Create GIN indexes for full-text search on Application.People
        IF NOT EXISTS (
            SELECT 1 FROM pg_indexes 
            WHERE indexname = 'idx_people_search_name_fts'
        ) THEN
            CREATE INDEX idx_people_search_name_fts 
            ON application.people 
            USING GIN (to_tsvector('english', COALESCE(search_name, '')));
        END IF;
        
        IF NOT EXISTS (
            SELECT 1 FROM pg_indexes 
            WHERE indexname = 'idx_people_custom_fields_fts'
        ) THEN
            CREATE INDEX idx_people_custom_fields_fts 
            ON application.people 
            USING GIN (to_tsvector('english', COALESCE(custom_fields::text, '')));
        END IF;
        
        -- Create GIN index for full-text search on Sales.Customers
        IF NOT EXISTS (
            SELECT 1 FROM pg_indexes 
            WHERE indexname = 'idx_customers_name_fts'
        ) THEN
            CREATE INDEX idx_customers_name_fts 
            ON sales.customers 
            USING GIN (to_tsvector('english', COALESCE(customer_name, '')));
        END IF;
        
        -- Create GIN index for full-text search on Purchasing.Suppliers
        IF NOT EXISTS (
            SELECT 1 FROM pg_indexes 
            WHERE indexname = 'idx_suppliers_name_fts'
        ) THEN
            CREATE INDEX idx_suppliers_name_fts 
            ON purchasing.suppliers 
            USING GIN (to_tsvector('english', COALESCE(supplier_name, '')));
        END IF;
        
        -- Create GIN indexes for full-text search on Warehouse.StockItems
        IF NOT EXISTS (
            SELECT 1 FROM pg_indexes 
            WHERE indexname = 'idx_stock_items_search_fts'
        ) THEN
            CREATE INDEX idx_stock_items_search_fts 
            ON warehouse.stock_items 
            USING GIN (to_tsvector('english', COALESCE(search_details, '')));
        END IF;
        
        IF NOT EXISTS (
            SELECT 1 FROM pg_indexes 
            WHERE indexname = 'idx_stock_items_tags_fts'
        ) THEN
            CREATE INDEX idx_stock_items_tags_fts 
            ON warehouse.stock_items 
            USING GIN (to_tsvector('english', COALESCE(tags::text, '')));
        END IF;
        
        RAISE NOTICE 'Full text indexing successfully enabled';
        
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Unable to apply full text indexing: %', SQLERRM;
        RAISE;
    END;
END;
$$;

COMMENT ON PROCEDURE application.configuration_apply_full_text_indexing IS 'Creates GIN indexes for PostgreSQL full-text search';
