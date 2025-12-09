-- Phase 3: OLTP Code Migration - Application Schema Stored Procedures
-- Converted from SQL Server T-SQL to PostgreSQL PL/pgSQL

-- =============================================
-- Procedure: Application.CreateRoleIfNonexistent
-- Description: Creates a database role if it doesn't already exist
-- =============================================
CREATE OR REPLACE PROCEDURE application.create_role_if_nonexistent(
    p_role_name varchar(128)
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = lower(p_role_name)) THEN
        EXECUTE format('CREATE ROLE %I', p_role_name);
        RAISE NOTICE 'Role % created', p_role_name;
    ELSE
        RAISE NOTICE 'Role % already exists', p_role_name;
    END IF;
END;
$$;

-- =============================================
-- Procedure: Application.AddRoleMemberIfNonexistent
-- Description: Adds a user to a role if not already a member
-- =============================================
CREATE OR REPLACE PROCEDURE application.add_role_member_if_nonexistent(
    p_role_name varchar(128),
    p_user_name varchar(128)
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT pg_has_role(p_user_name, p_role_name, 'MEMBER') THEN
        EXECUTE format('GRANT %I TO %I', p_role_name, p_user_name);
        RAISE NOTICE 'User % added to role %', p_user_name, p_role_name;
    ELSE
        RAISE NOTICE 'User % is already a member of role %', p_user_name, p_role_name;
    END IF;
EXCEPTION
    WHEN undefined_object THEN
        RAISE NOTICE 'Role % or user % does not exist', p_role_name, p_user_name;
END;
$$;

-- =============================================
-- Procedure: Application.Configuration_ApplyRowLevelSecurity
-- Description: Applies row-level security policies to the Sales.Customers table
-- =============================================
CREATE OR REPLACE PROCEDURE application.configuration_apply_row_level_security()
LANGUAGE plpgsql
AS $$
BEGIN
    -- Drop existing policy if it exists
    DROP POLICY IF EXISTS filter_customers_by_sales_territory ON sales.customers;
    
    -- Enable RLS on the customers table
    ALTER TABLE sales.customers ENABLE ROW LEVEL SECURITY;
    
    -- Create the filter policy
    CREATE POLICY filter_customers_by_sales_territory ON sales.customers
        FOR ALL
        USING (
            EXISTS (SELECT 1 FROM application.determine_customer_access(deliverycityid))
        );
    
    -- Force RLS for table owner as well (optional, depends on requirements)
    ALTER TABLE sales.customers FORCE ROW LEVEL SECURITY;
    
    RAISE NOTICE 'Successfully applied row level security';
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Unable to apply row level security: %', SQLERRM;
        RAISE EXCEPTION 'Unable to apply row level security'
            USING ERRCODE = '51000';
END;
$$;

-- =============================================
-- Procedure: Application.Configuration_RemoveRowLevelSecurity
-- Description: Removes row-level security policies from the Sales.Customers table
-- =============================================
CREATE OR REPLACE PROCEDURE application.configuration_remove_row_level_security()
LANGUAGE plpgsql
AS $$
BEGIN
    -- Drop the policy
    DROP POLICY IF EXISTS filter_customers_by_sales_territory ON sales.customers;
    
    -- Disable RLS on the customers table
    ALTER TABLE sales.customers DISABLE ROW LEVEL SECURITY;
    ALTER TABLE sales.customers NO FORCE ROW LEVEL SECURITY;
    
    RAISE NOTICE 'Successfully removed row level security';
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Unable to remove row level security: %', SQLERRM;
END;
$$;

-- =============================================
-- Procedure: Application.Configuration_ApplyAuditing
-- Description: Sets up auditing for the database (PostgreSQL equivalent using pgaudit)
-- Note: Requires pgaudit extension to be installed
-- =============================================
CREATE OR REPLACE PROCEDURE application.configuration_apply_auditing()
LANGUAGE plpgsql
AS $$
BEGIN
    -- Check if pgaudit extension is available
    IF EXISTS (SELECT 1 FROM pg_available_extensions WHERE name = 'pgaudit') THEN
        CREATE EXTENSION IF NOT EXISTS pgaudit;
        
        -- Configure audit settings (these would typically be in postgresql.conf)
        -- ALTER SYSTEM SET pgaudit.log = 'write, ddl';
        -- ALTER SYSTEM SET pgaudit.log_catalog = off;
        
        RAISE NOTICE 'Auditing configuration applied. Note: pgaudit settings may require server restart.';
    ELSE
        RAISE NOTICE 'pgaudit extension is not available. Auditing not configured.';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Unable to apply auditing: %', SQLERRM;
END;
$$;

-- =============================================
-- Procedure: Application.Configuration_RemoveAuditing
-- Description: Removes auditing configuration
-- =============================================
CREATE OR REPLACE PROCEDURE application.configuration_remove_auditing()
LANGUAGE plpgsql
AS $$
BEGIN
    -- Drop pgaudit extension if it exists
    DROP EXTENSION IF EXISTS pgaudit;
    RAISE NOTICE 'Auditing configuration removed';
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Unable to remove auditing: %', SQLERRM;
END;
$$;

-- =============================================
-- Procedure: Application.Configuration_ApplyFullTextIndexing
-- Description: Creates full-text search indexes on relevant tables
-- =============================================
CREATE OR REPLACE PROCEDURE application.configuration_apply_full_text_indexing()
LANGUAGE plpgsql
AS $$
BEGIN
    -- Create GIN indexes for full-text search on People table
    CREATE INDEX IF NOT EXISTS ix_application_people_fulltext 
    ON application.people USING gin(to_tsvector('english', 
        coalesce(fullname, '') || ' ' || 
        coalesce(preferredname, '') || ' ' || 
        coalesce(searchname, '')));
    
    -- Create GIN indexes for full-text search on Customers table
    CREATE INDEX IF NOT EXISTS ix_sales_customers_fulltext 
    ON sales.customers USING gin(to_tsvector('english', 
        coalesce(customername, '') || ' ' || 
        coalesce(deliveryaddressline1, '') || ' ' || 
        coalesce(deliveryaddressline2, '')));
    
    -- Create GIN indexes for full-text search on Suppliers table
    CREATE INDEX IF NOT EXISTS ix_purchasing_suppliers_fulltext 
    ON purchasing.suppliers USING gin(to_tsvector('english', 
        coalesce(suppliername, '') || ' ' || 
        coalesce(deliveryaddressline1, '') || ' ' || 
        coalesce(deliveryaddressline2, '')));
    
    -- Create GIN indexes for full-text search on StockItems table
    CREATE INDEX IF NOT EXISTS ix_warehouse_stockitems_fulltext 
    ON warehouse.stockitems USING gin(to_tsvector('english', 
        coalesce(stockitemname, '') || ' ' || 
        coalesce(searchdetails, '') || ' ' || 
        coalesce(marketingcomments, '')));
    
    -- Create GIN index for tags on StockItems (JSONB)
    CREATE INDEX IF NOT EXISTS ix_warehouse_stockitems_tags 
    ON warehouse.stockitems USING gin(tags jsonb_path_ops);
    
    RAISE NOTICE 'Successfully applied full-text indexing';
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Unable to apply full-text indexing: %', SQLERRM;
END;
$$;

-- =============================================
-- Procedure: Application.Configuration_ApplyColumnstoreIndexing
-- Description: Creates indexes optimized for analytical queries (PostgreSQL equivalent)
-- Note: PostgreSQL doesn't have columnstore indexes, but we can use BRIN indexes for similar benefits
-- =============================================
CREATE OR REPLACE PROCEDURE application.configuration_apply_columnstore_indexing()
LANGUAGE plpgsql
AS $$
BEGIN
    -- Create BRIN indexes on large tables for analytical queries
    -- BRIN indexes are efficient for large tables with naturally ordered data
    
    CREATE INDEX IF NOT EXISTS ix_sales_invoicelines_brin 
    ON sales.invoicelines USING brin(invoiceid);
    
    CREATE INDEX IF NOT EXISTS ix_sales_orderlines_brin 
    ON sales.orderlines USING brin(orderid);
    
    CREATE INDEX IF NOT EXISTS ix_warehouse_stockitemtransactions_brin 
    ON warehouse.stockitemtransactions USING brin(transactionoccurredwhen);
    
    CREATE INDEX IF NOT EXISTS ix_sales_customertransactions_brin 
    ON sales.customertransactions USING brin(transactiondate);
    
    CREATE INDEX IF NOT EXISTS ix_purchasing_suppliertransactions_brin 
    ON purchasing.suppliertransactions USING brin(transactiondate);
    
    RAISE NOTICE 'Successfully applied columnstore-equivalent indexing (BRIN indexes)';
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Unable to apply columnstore indexing: %', SQLERRM;
END;
$$;

-- =============================================
-- Procedure: Application.Configuration_RemoveColumnstoreIndexing
-- Description: Removes columnstore-equivalent indexes
-- =============================================
CREATE OR REPLACE PROCEDURE application.configuration_remove_columnstore_indexing()
LANGUAGE plpgsql
AS $$
BEGIN
    DROP INDEX IF EXISTS sales.ix_sales_invoicelines_brin;
    DROP INDEX IF EXISTS sales.ix_sales_orderlines_brin;
    DROP INDEX IF EXISTS warehouse.ix_warehouse_stockitemtransactions_brin;
    DROP INDEX IF EXISTS sales.ix_sales_customertransactions_brin;
    DROP INDEX IF EXISTS purchasing.ix_purchasing_suppliertransactions_brin;
    
    RAISE NOTICE 'Successfully removed columnstore-equivalent indexing';
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Unable to remove columnstore indexing: %', SQLERRM;
END;
$$;

-- =============================================
-- Procedure: Application.Configuration_ApplyPartitioning
-- Description: Applies table partitioning for large tables
-- Note: This is a simplified version - actual partitioning would require table recreation
-- =============================================
CREATE OR REPLACE PROCEDURE application.configuration_apply_partitioning()
LANGUAGE plpgsql
AS $$
BEGIN
    -- Note: PostgreSQL partitioning requires tables to be created as partitioned from the start
    -- This procedure documents what would be partitioned in a full implementation
    
    RAISE NOTICE 'Partitioning configuration:';
    RAISE NOTICE '- Sales.CustomerTransactions would be partitioned by TransactionDate (RANGE)';
    RAISE NOTICE '- Sales.InvoiceLines would be partitioned by InvoiceID (RANGE)';
    RAISE NOTICE '- Warehouse.StockItemTransactions would be partitioned by TransactionOccurredWhen (RANGE)';
    RAISE NOTICE 'Note: Actual partitioning requires table recreation with PARTITION BY clause';
END;
$$;

-- =============================================
-- Procedure: Application.Configuration_DisableInMemory
-- Description: PostgreSQL equivalent - converts any special table configurations to standard
-- Note: PostgreSQL doesn't have memory-optimized tables like SQL Server
-- =============================================
CREATE OR REPLACE PROCEDURE application.configuration_disable_in_memory()
LANGUAGE plpgsql
AS $$
BEGIN
    -- In PostgreSQL, there's no direct equivalent to SQL Server's memory-optimized tables
    -- The tables are already standard PostgreSQL tables
    -- This procedure ensures the Website schema procedures exist with standard implementations
    
    RAISE NOTICE 'PostgreSQL does not have memory-optimized tables.';
    RAISE NOTICE 'All tables are using standard PostgreSQL storage.';
    RAISE NOTICE 'Website procedures are available with standard implementations.';
END;
$$;

-- =============================================
-- Procedure: Application.Configuration_EnableInMemory
-- Description: PostgreSQL equivalent - would enable any special optimizations
-- Note: PostgreSQL doesn't have memory-optimized tables like SQL Server
-- =============================================
CREATE OR REPLACE PROCEDURE application.configuration_enable_in_memory()
LANGUAGE plpgsql
AS $$
BEGIN
    -- In PostgreSQL, we can use UNLOGGED tables for better performance (no WAL)
    -- However, this is not recommended for production data as it's not crash-safe
    
    RAISE NOTICE 'PostgreSQL does not have memory-optimized tables like SQL Server.';
    RAISE NOTICE 'Consider using UNLOGGED tables for temporary/cache data (not crash-safe).';
    RAISE NOTICE 'Consider using pg_prewarm extension to keep frequently accessed data in memory.';
END;
$$;

-- =============================================
-- Procedure: Application.Configuration_ConfigureForEnterpriseEdition
-- Description: Applies enterprise-level configurations
-- =============================================
CREATE OR REPLACE PROCEDURE application.configuration_configure_for_enterprise_edition()
LANGUAGE plpgsql
AS $$
BEGIN
    -- Apply all enterprise-level configurations
    CALL application.configuration_apply_row_level_security();
    CALL application.configuration_apply_full_text_indexing();
    CALL application.configuration_apply_columnstore_indexing();
    
    RAISE NOTICE 'Enterprise edition configuration applied';
END;
$$;

-- =============================================
-- Procedure: Application.Configuration_PrepareForAzureStandard
-- Description: Prepares database for Azure PostgreSQL Standard tier
-- =============================================
CREATE OR REPLACE PROCEDURE application.configuration_prepare_for_azure_standard()
LANGUAGE plpgsql
AS $$
BEGIN
    -- Remove features not available in standard tier
    CALL application.configuration_remove_row_level_security();
    
    RAISE NOTICE 'Database prepared for Azure PostgreSQL Standard tier';
END;
$$;

COMMENT ON PROCEDURE application.create_role_if_nonexistent(varchar) IS 
'Creates a database role if it does not already exist';

COMMENT ON PROCEDURE application.add_role_member_if_nonexistent(varchar, varchar) IS 
'Adds a user to a role if not already a member';

COMMENT ON PROCEDURE application.configuration_apply_row_level_security() IS 
'Applies row-level security policies to the Sales.Customers table';

COMMENT ON PROCEDURE application.configuration_remove_row_level_security() IS 
'Removes row-level security policies from the Sales.Customers table';
