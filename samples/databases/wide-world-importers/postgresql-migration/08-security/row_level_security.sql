-- Wide World Importers PostgreSQL Migration
-- Row-Level Security Implementation
-- This script creates roles and row-level security policies equivalent to SQL Server's implementation

-- Create database roles for sales territories
CREATE ROLE "db_owner" NOLOGIN;
CREATE ROLE "Far West Sales" NOLOGIN;
CREATE ROLE "Great Lakes Sales" NOLOGIN;
CREATE ROLE "Mideast Sales" NOLOGIN;
CREATE ROLE "New England Sales" NOLOGIN;
CREATE ROLE "Plains Sales" NOLOGIN;
CREATE ROLE "Rocky Mountain Sales" NOLOGIN;
CREATE ROLE "Southeast Sales" NOLOGIN;
CREATE ROLE "Southwest Sales" NOLOGIN;
CREATE ROLE "External Sales" NOLOGIN;

-- Create application roles
CREATE ROLE website LOGIN PASSWORD 'WebsitePassword123!';
CREATE ROLE webapi LOGIN PASSWORD 'WebApiPassword123!';

-- Grant schema usage to roles
GRANT USAGE ON SCHEMA application TO website, webapi;
GRANT USAGE ON SCHEMA sales TO website, webapi;
GRANT USAGE ON SCHEMA purchasing TO website, webapi;
GRANT USAGE ON SCHEMA warehouse TO website, webapi;
GRANT USAGE ON SCHEMA website TO website;
GRANT USAGE ON SCHEMA webapi TO webapi;
GRANT USAGE ON SCHEMA sequences TO website, webapi;

-- Grant table permissions
GRANT SELECT ON ALL TABLES IN SCHEMA application TO website, webapi;
GRANT SELECT ON ALL TABLES IN SCHEMA sales TO website, webapi;
GRANT SELECT ON ALL TABLES IN SCHEMA purchasing TO website, webapi;
GRANT SELECT ON ALL TABLES IN SCHEMA warehouse TO website, webapi;
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA website TO website;
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA webapi TO webapi;

-- Grant sequence permissions
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA sequences TO website, webapi;

-- Enable Row-Level Security on Customers table
ALTER TABLE sales.customers ENABLE ROW LEVEL SECURITY;

-- Create RLS policy for Customers table
-- This policy restricts access based on sales territory
CREATE POLICY customers_sales_territory_policy ON sales.customers
    FOR ALL
    USING (
        -- db_owner can see all customers
        pg_has_role(current_user, 'db_owner', 'MEMBER')
        -- Users in sales territory roles can see customers in their territory
        OR EXISTS (
            SELECT 1
            FROM application.cities c
            INNER JOIN application.stateprovinces sp ON c.stateprovinceid = sp.stateprovinceid
            WHERE c.cityid = sales.customers.deliverycityid
            AND pg_has_role(current_user, sp.salesterritory || ' Sales', 'MEMBER')
        )
        -- Website and WebApi users can see customers based on session context
        OR (
            (current_user = 'website' OR current_user = 'webapi')
            AND EXISTS (
                SELECT 1
                FROM application.cities c
                INNER JOIN application.stateprovinces sp ON c.stateprovinceid = sp.stateprovinceid
                WHERE c.cityid = sales.customers.deliverycityid
                AND sp.salesterritory = current_setting('app.sales_territory', true)
            )
        )
    );

-- Create helper function to set sales territory for session
-- This replaces SQL Server's SESSION_CONTEXT functionality
CREATE OR REPLACE FUNCTION set_sales_territory(p_territory varchar)
RETURNS void AS $$
BEGIN
    PERFORM set_config('app.sales_territory', p_territory, false);
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION set_sales_territory(varchar) IS 'Sets the sales territory for the current session (replaces SQL Server SESSION_CONTEXT)';

-- Create helper function to get current sales territory
CREATE OR REPLACE FUNCTION get_sales_territory()
RETURNS varchar AS $$
BEGIN
    RETURN current_setting('app.sales_territory', true);
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_sales_territory() IS 'Gets the sales territory for the current session';

-- Example: Grant a user to a sales territory role
-- GRANT "Far West Sales" TO some_user;

-- Example: Set sales territory for website/webapi session
-- SELECT set_sales_territory('Far West');

-- Configuration procedure to apply row-level security
CREATE OR REPLACE FUNCTION application.configuration_apply_row_level_security()
RETURNS void AS $$
BEGIN
    -- Enable RLS on customers table
    ALTER TABLE sales.customers ENABLE ROW LEVEL SECURITY;
    
    -- Force RLS for table owner as well (optional, for testing)
    -- ALTER TABLE sales.customers FORCE ROW LEVEL SECURITY;
    
    RAISE NOTICE 'Row-level security has been applied to Sales.Customers table';
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION application.configuration_apply_row_level_security() IS 'Applies row-level security to the Customers table';

-- Configuration procedure to remove row-level security
CREATE OR REPLACE FUNCTION application.configuration_remove_row_level_security()
RETURNS void AS $$
BEGIN
    -- Disable RLS on customers table
    ALTER TABLE sales.customers DISABLE ROW LEVEL SECURITY;
    
    RAISE NOTICE 'Row-level security has been removed from Sales.Customers table';
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION application.configuration_remove_row_level_security() IS 'Removes row-level security from the Customers table';

-- Create role membership helper function
CREATE OR REPLACE FUNCTION application.add_role_member_if_nonexistent(
    p_role_name varchar,
    p_member_name varchar
)
RETURNS void AS $$
BEGIN
    -- Check if role exists
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = p_role_name) THEN
        EXECUTE format('CREATE ROLE %I NOLOGIN', p_role_name);
    END IF;
    
    -- Grant role to member
    EXECUTE format('GRANT %I TO %I', p_role_name, p_member_name);
EXCEPTION
    WHEN duplicate_object THEN
        -- Role membership already exists, ignore
        NULL;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION application.add_role_member_if_nonexistent(varchar, varchar) IS 'Adds a member to a role, creating the role if it does not exist';

-- Create role helper function
CREATE OR REPLACE FUNCTION application.create_role_if_nonexistent(
    p_role_name varchar
)
RETURNS void AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = p_role_name) THEN
        EXECUTE format('CREATE ROLE %I NOLOGIN', p_role_name);
    END IF;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION application.create_role_if_nonexistent(varchar) IS 'Creates a role if it does not exist';
