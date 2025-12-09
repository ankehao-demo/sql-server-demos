-- PostgreSQL equivalent of [Application].Configuration_RemoveRowLevelSecurity
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE PROCEDURE application.configuration_remove_row_level_security()
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    BEGIN
        -- Drop the policy
        DROP POLICY IF EXISTS customer_territory_access ON sales.customers;
        
        -- Disable RLS on the table
        ALTER TABLE sales.customers DISABLE ROW LEVEL SECURITY;
        
        -- Drop the predicate function
        DROP FUNCTION IF EXISTS application.determine_customer_access(INTEGER);
        
        RAISE NOTICE 'Successfully removed row level security';
        
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Unable to remove row level security';
        RAISE EXCEPTION 'Unable to remove row level security' USING ERRCODE = '51000';
    END;
END;
$$;

COMMENT ON PROCEDURE application.configuration_remove_row_level_security IS 'Removes row-level security from Sales.Customers';
