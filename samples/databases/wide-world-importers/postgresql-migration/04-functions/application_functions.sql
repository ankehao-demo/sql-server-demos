-- Wide World Importers PostgreSQL Migration
-- Application Functions
-- This script creates all functions in the Application schema

-- DetermineCustomerAccess function
-- This function is used for row-level security to determine if a user can access customer data
-- based on their sales territory role
CREATE OR REPLACE FUNCTION application.determine_customer_access(p_cityid integer)
RETURNS TABLE (accessresult integer) AS $$
BEGIN
    RETURN QUERY
    SELECT 1 AS accessresult
    WHERE 
        -- Check if user is db_owner (superuser in PostgreSQL)
        current_user = 'postgres' OR pg_has_role(current_user, 'db_owner', 'MEMBER')
        -- Check if user is member of the appropriate sales territory role
        OR pg_has_role(current_user, (
            SELECT sp.salesterritory || ' Sales'
            FROM application.cities AS c
            INNER JOIN application.stateprovinces AS sp
            ON c.stateprovinceid = sp.stateprovinceid
            WHERE c.cityid = p_cityid
        ), 'MEMBER')
        -- Check if user is Website or WebApi and has matching sales territory in session
        OR (
            (current_user = 'website' OR current_user = 'webapi')
            AND EXISTS (
                SELECT 1
                FROM application.cities AS c
                INNER JOIN application.stateprovinces AS sp
                ON c.stateprovinceid = sp.stateprovinceid
                WHERE c.cityid = p_cityid
                AND sp.salesterritory = current_setting('app.sales_territory', true)
            )
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION application.determine_customer_access(integer) IS 'Determines if the current user has access to customer data based on sales territory';

-- Helper function to set sales territory for session (replaces SESSION_CONTEXT)
CREATE OR REPLACE FUNCTION application.set_sales_territory(p_territory varchar)
RETURNS void AS $$
BEGIN
    PERFORM set_config('app.sales_territory', p_territory, false);
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION application.set_sales_territory(varchar) IS 'Sets the sales territory for the current session';

-- Helper function to get sales territory for session
CREATE OR REPLACE FUNCTION application.get_sales_territory()
RETURNS varchar AS $$
BEGIN
    RETURN current_setting('app.sales_territory', true);
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION application.get_sales_territory() IS 'Gets the sales territory for the current session';
