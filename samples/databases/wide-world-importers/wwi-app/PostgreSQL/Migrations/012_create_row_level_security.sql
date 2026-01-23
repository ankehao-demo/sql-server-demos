-- Wide World Importers PostgreSQL Migration
-- Script 012: Create Row-Level Security (RLS)
-- Migrated from SQL Server to PostgreSQL
--
-- SQL Server uses SECURITY POLICY with FILTER and BLOCK predicates
-- PostgreSQL uses CREATE POLICY with USING (filter) and WITH CHECK (block) clauses

-- Enable Row-Level Security on the customers table
ALTER TABLE sales.customers ENABLE ROW LEVEL SECURITY;

-- Create roles for sales territories (matching SQL Server roles)
DO $$
BEGIN
    -- Create sales territory roles if they don't exist
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'great_lakes_sales') THEN
        CREATE ROLE great_lakes_sales;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'plains_sales') THEN
        CREATE ROLE plains_sales;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'far_west_sales') THEN
        CREATE ROLE far_west_sales;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'new_england_sales') THEN
        CREATE ROLE new_england_sales;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'mideast_sales') THEN
        CREATE ROLE mideast_sales;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'southeast_sales') THEN
        CREATE ROLE southeast_sales;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'southwest_sales') THEN
        CREATE ROLE southwest_sales;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'rocky_mountain_sales') THEN
        CREATE ROLE rocky_mountain_sales;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'webapi') THEN
        CREATE ROLE webapi;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'website') THEN
        CREATE ROLE website;
    END IF;
END
$$;

-- Function to determine customer access based on sales territory
-- This replicates the SQL Server DetermineCustomerAccess function
CREATE OR REPLACE FUNCTION application.determine_customer_access(p_city_id INTEGER)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
AS $$
DECLARE
    v_sales_territory VARCHAR(50);
    v_session_territory VARCHAR(50);
BEGIN
    -- db_owner equivalent (superuser or owner) always has access
    IF current_user = 'postgres' OR 
       pg_has_role(current_user, 'rds_superuser', 'MEMBER') OR
       pg_has_role(current_user, 'db_owner', 'MEMBER') THEN
        RETURN TRUE;
    END IF;

    -- Get the sales territory for the city
    SELECT sp.sales_territory INTO v_sales_territory
    FROM application.cities c
    INNER JOIN application.state_provinces sp ON c.state_province_id = sp.state_province_id
    WHERE c.city_id = p_city_id;

    -- Check if user is a member of the appropriate sales territory role
    IF v_sales_territory IS NOT NULL THEN
        -- Convert territory name to role name (e.g., "Great Lakes" -> "great_lakes_sales")
        IF pg_has_role(current_user, lower(replace(v_sales_territory, ' ', '_')) || '_sales', 'MEMBER') THEN
            RETURN TRUE;
        END IF;
    END IF;

    -- Check for WebAPI/Website users with session context
    IF pg_has_role(current_user, 'webapi', 'MEMBER') OR 
       pg_has_role(current_user, 'website', 'MEMBER') THEN
        -- Get territory from session context (set via SET LOCAL or current_setting)
        BEGIN
            v_session_territory := current_setting('app.sales_territory', TRUE);
        EXCEPTION
            WHEN OTHERS THEN
                v_session_territory := NULL;
        END;

        -- Special case: ALL_TERRITORIES grants access to everything
        IF v_session_territory = 'ALL_TERRITORIES' THEN
            RETURN TRUE;
        END IF;

        -- Check if session territory matches the city's territory
        IF v_session_territory IS NOT NULL AND v_session_territory = v_sales_territory THEN
            RETURN TRUE;
        END IF;
    END IF;

    RETURN FALSE;
END;
$$;

COMMENT ON FUNCTION application.determine_customer_access IS 'Determines if the current user has access to a customer based on sales territory';

-- Create RLS policy for customers table (filter predicate)
-- This controls which rows users can SELECT
DROP POLICY IF EXISTS filter_customers_by_sales_territory ON sales.customers;
CREATE POLICY filter_customers_by_sales_territory
    ON sales.customers
    FOR SELECT
    USING (application.determine_customer_access(delivery_city_id));

-- Create RLS policy for customers table (block predicate for UPDATE)
-- This prevents users from updating customers to move them outside their territory
DROP POLICY IF EXISTS block_customers_update_by_sales_territory ON sales.customers;
CREATE POLICY block_customers_update_by_sales_territory
    ON sales.customers
    FOR UPDATE
    USING (application.determine_customer_access(delivery_city_id))
    WITH CHECK (application.determine_customer_access(delivery_city_id));

-- Create RLS policy for customers table (INSERT)
DROP POLICY IF EXISTS block_customers_insert_by_sales_territory ON sales.customers;
CREATE POLICY block_customers_insert_by_sales_territory
    ON sales.customers
    FOR INSERT
    WITH CHECK (application.determine_customer_access(delivery_city_id));

-- Create RLS policy for customers table (DELETE)
DROP POLICY IF EXISTS block_customers_delete_by_sales_territory ON sales.customers;
CREATE POLICY block_customers_delete_by_sales_territory
    ON sales.customers
    FOR DELETE
    USING (application.determine_customer_access(delivery_city_id));

-- Grant permissions to sales territory roles
GRANT SELECT, UPDATE ON sales.customers TO great_lakes_sales;
GRANT SELECT, UPDATE ON sales.customers TO plains_sales;
GRANT SELECT, UPDATE ON sales.customers TO far_west_sales;
GRANT SELECT, UPDATE ON sales.customers TO new_england_sales;
GRANT SELECT, UPDATE ON sales.customers TO mideast_sales;
GRANT SELECT, UPDATE ON sales.customers TO southeast_sales;
GRANT SELECT, UPDATE ON sales.customers TO southwest_sales;
GRANT SELECT, UPDATE ON sales.customers TO rocky_mountain_sales;
GRANT SELECT, UPDATE ON sales.customers TO webapi;
GRANT SELECT, UPDATE ON sales.customers TO website;

-- Grant SELECT on supporting tables needed for RLS function
GRANT SELECT ON application.cities TO great_lakes_sales, plains_sales, far_west_sales, 
    new_england_sales, mideast_sales, southeast_sales, southwest_sales, rocky_mountain_sales,
    webapi, website;
GRANT SELECT ON application.state_provinces TO great_lakes_sales, plains_sales, far_west_sales,
    new_england_sales, mideast_sales, southeast_sales, southwest_sales, rocky_mountain_sales,
    webapi, website;
GRANT SELECT ON application.countries TO great_lakes_sales, plains_sales, far_west_sales,
    new_england_sales, mideast_sales, southeast_sales, southwest_sales, rocky_mountain_sales,
    webapi, website;

-- Helper function to set sales territory for session
-- This should be called at the beginning of a session/request
CREATE OR REPLACE FUNCTION application.set_sales_territory(p_territory VARCHAR(50))
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
    PERFORM set_config('app.sales_territory', p_territory, FALSE);
END;
$$;

COMMENT ON FUNCTION application.set_sales_territory IS 'Sets the sales territory for the current session (used by WebAPI/Website)';

-- Helper function to get current sales territory
CREATE OR REPLACE FUNCTION application.get_sales_territory()
RETURNS VARCHAR(50)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN current_setting('app.sales_territory', TRUE);
END;
$$;

COMMENT ON FUNCTION application.get_sales_territory IS 'Gets the sales territory for the current session';

-- Procedure to apply row-level security (equivalent to SQL Server Configuration_ApplyRowLevelSecurity)
CREATE OR REPLACE FUNCTION application.configuration_apply_row_level_security()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Enable RLS on customers table
    ALTER TABLE sales.customers ENABLE ROW LEVEL SECURITY;
    
    -- Force RLS for table owner as well (optional, for testing)
    -- ALTER TABLE sales.customers FORCE ROW LEVEL SECURITY;
    
    RAISE NOTICE 'Successfully applied row level security';
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Unable to apply row level security: %', SQLERRM;
END;
$$;

COMMENT ON FUNCTION application.configuration_apply_row_level_security IS 'Applies row-level security to the customers table';

-- Procedure to remove row-level security
CREATE OR REPLACE FUNCTION application.configuration_remove_row_level_security()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Disable RLS on customers table
    ALTER TABLE sales.customers DISABLE ROW LEVEL SECURITY;
    
    -- Drop policies
    DROP POLICY IF EXISTS filter_customers_by_sales_territory ON sales.customers;
    DROP POLICY IF EXISTS block_customers_update_by_sales_territory ON sales.customers;
    DROP POLICY IF EXISTS block_customers_insert_by_sales_territory ON sales.customers;
    DROP POLICY IF EXISTS block_customers_delete_by_sales_territory ON sales.customers;
    
    RAISE NOTICE 'Successfully removed row level security';
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Unable to remove row level security: %', SQLERRM;
END;
$$;

COMMENT ON FUNCTION application.configuration_remove_row_level_security IS 'Removes row-level security from the customers table';

-- Additional RLS for related tables that should respect customer access

-- Enable RLS on orders table
ALTER TABLE sales.orders ENABLE ROW LEVEL SECURITY;

-- Create function to check order access via customer
CREATE OR REPLACE FUNCTION application.determine_order_access(p_customer_id INTEGER)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
AS $$
DECLARE
    v_city_id INTEGER;
BEGIN
    -- Get the delivery city for the customer
    SELECT delivery_city_id INTO v_city_id
    FROM sales.customers
    WHERE customer_id = p_customer_id;

    -- Use the customer access function
    RETURN application.determine_customer_access(v_city_id);
END;
$$;

-- Create RLS policy for orders table
DROP POLICY IF EXISTS filter_orders_by_customer_territory ON sales.orders;
CREATE POLICY filter_orders_by_customer_territory
    ON sales.orders
    FOR ALL
    USING (application.determine_order_access(customer_id));

-- Enable RLS on invoices table
ALTER TABLE sales.invoices ENABLE ROW LEVEL SECURITY;

-- Create RLS policy for invoices table
DROP POLICY IF EXISTS filter_invoices_by_customer_territory ON sales.invoices;
CREATE POLICY filter_invoices_by_customer_territory
    ON sales.invoices
    FOR ALL
    USING (application.determine_order_access(customer_id));

-- Enable RLS on customer_transactions table
ALTER TABLE sales.customer_transactions ENABLE ROW LEVEL SECURITY;

-- Create RLS policy for customer_transactions table
DROP POLICY IF EXISTS filter_customer_transactions_by_territory ON sales.customer_transactions;
CREATE POLICY filter_customer_transactions_by_territory
    ON sales.customer_transactions
    FOR ALL
    USING (application.determine_order_access(customer_id));

-- Grant permissions on related tables
GRANT SELECT ON sales.orders TO great_lakes_sales, plains_sales, far_west_sales,
    new_england_sales, mideast_sales, southeast_sales, southwest_sales, rocky_mountain_sales,
    webapi, website;
GRANT SELECT ON sales.invoices TO great_lakes_sales, plains_sales, far_west_sales,
    new_england_sales, mideast_sales, southeast_sales, southwest_sales, rocky_mountain_sales,
    webapi, website;
GRANT SELECT ON sales.customer_transactions TO great_lakes_sales, plains_sales, far_west_sales,
    new_england_sales, mideast_sales, southeast_sales, southwest_sales, rocky_mountain_sales,
    webapi, website;

-- Example usage:
-- 
-- 1. Create a user and assign to a sales territory role:
--    CREATE USER great_lakes_user WITH PASSWORD 'password';
--    GRANT great_lakes_sales TO great_lakes_user;
--
-- 2. For WebAPI/Website users, set the territory at session start:
--    SELECT application.set_sales_territory('Great Lakes');
--    -- or for full access:
--    SELECT application.set_sales_territory('ALL_TERRITORIES');
--
-- 3. Query customers - RLS will automatically filter results:
--    SELECT * FROM sales.customers;
