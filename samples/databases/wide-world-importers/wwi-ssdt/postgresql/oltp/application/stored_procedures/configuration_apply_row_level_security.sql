-- PostgreSQL equivalent of [Application].Configuration_ApplyRowLevelSecurity
-- Converted from T-SQL to PL/pgSQL
-- Note: PostgreSQL uses native RLS with CREATE POLICY instead of SQL Server's SECURITY POLICY

CREATE OR REPLACE PROCEDURE application.configuration_apply_row_level_security()
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    BEGIN
        -- Drop existing policy if it exists
        DROP POLICY IF EXISTS customer_territory_access ON sales.customers;
        
        -- Drop existing function if it exists
        DROP FUNCTION IF EXISTS application.determine_customer_access(INTEGER);
        
        -- Create the RLS predicate function
        -- This function determines if the current user has access to a customer based on territory
        CREATE OR REPLACE FUNCTION application.determine_customer_access(p_city_id INTEGER)
        RETURNS BOOLEAN
        LANGUAGE plpgsql
        STABLE
        SECURITY DEFINER
        AS $func$
        BEGIN
            RETURN (
                -- db_owner equivalent (admin role) has full access
                pg_has_role(current_user, 'wwi_admin', 'MEMBER')
                OR
                -- Territory-based access via role membership
                EXISTS (
                    SELECT 1 
                    FROM application.cities c
                    JOIN application.state_provinces sp ON c.state_province_id = sp.state_province_id
                    WHERE c.city_id = p_city_id
                    AND pg_has_role(current_user, sp.sales_territory || ' Sales', 'MEMBER')
                )
                OR
                -- Website/WebApi user with session context
                (
                    (session_user = 'website' OR session_user = 'webapi')
                    AND EXISTS (
                        SELECT 1 
                        FROM application.cities c
                        JOIN application.state_provinces sp ON c.state_province_id = sp.state_province_id
                        WHERE c.city_id = p_city_id
                        AND sp.sales_territory = COALESCE(current_setting('app.sales_territory', true), '')
                    )
                )
            );
        END;
        $func$;
        
        -- Enable RLS on the customers table
        ALTER TABLE sales.customers ENABLE ROW LEVEL SECURITY;
        
        -- Create the policy for SELECT, UPDATE, DELETE operations
        CREATE POLICY customer_territory_access ON sales.customers
        FOR ALL
        USING (application.determine_customer_access(delivery_city_id))
        WITH CHECK (application.determine_customer_access(delivery_city_id));
        
        RAISE NOTICE 'Successfully applied row level security';
        
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Unable to apply row level security';
        RAISE EXCEPTION 'Unable to apply row level security' USING ERRCODE = '51000';
    END;
END;
$$;

COMMENT ON PROCEDURE application.configuration_apply_row_level_security IS 'Enables row-level security on Sales.Customers based on sales territory';
