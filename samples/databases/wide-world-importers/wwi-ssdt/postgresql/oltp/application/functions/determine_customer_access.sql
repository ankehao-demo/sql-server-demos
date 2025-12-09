-- PostgreSQL equivalent of [Application].DetermineCustomerAccess
-- Converted from T-SQL to PL/pgSQL
-- This is the RLS predicate function used for row-level security on Sales.Customers

CREATE OR REPLACE FUNCTION application.determine_customer_access(p_city_id INTEGER)
RETURNS BOOLEAN
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
AS $$
DECLARE
    v_sales_territory VARCHAR(50);
    v_has_access BOOLEAN := false;
BEGIN
    -- Check if user is db_owner equivalent (admin role)
    IF pg_has_role(current_user, 'wwi_admin', 'MEMBER') THEN
        RETURN true;
    END IF;
    
    -- Get the sales territory for the given city
    SELECT sp.sales_territory INTO v_sales_territory
    FROM application.cities c
    JOIN application.state_provinces sp ON c.state_province_id = sp.state_province_id
    WHERE c.city_id = p_city_id;
    
    -- Check if user is a member of the territory's sales role
    IF v_sales_territory IS NOT NULL THEN
        BEGIN
            IF pg_has_role(current_user, v_sales_territory || ' Sales', 'MEMBER') THEN
                RETURN true;
            END IF;
        EXCEPTION WHEN undefined_object THEN
            -- Role doesn't exist, continue checking
            NULL;
        END;
    END IF;
    
    -- Check for Website/WebApi user with session context
    IF session_user IN ('website', 'webapi') THEN
        -- Check if the city's territory matches the session context
        IF EXISTS (
            SELECT 1 
            FROM application.cities c
            JOIN application.state_provinces sp ON c.state_province_id = sp.state_province_id
            WHERE c.city_id = p_city_id
            AND sp.sales_territory = COALESCE(current_setting('app.sales_territory', true), '')
        ) THEN
            RETURN true;
        END IF;
    END IF;
    
    RETURN false;
END;
$$;

COMMENT ON FUNCTION application.determine_customer_access IS 'RLS predicate function that determines customer access based on sales territory';

-- Alternative inline table-valued function style (returns table like SQL Server)
-- This can be used for more complex RLS scenarios
CREATE OR REPLACE FUNCTION application.determine_customer_access_tvf(p_city_id INTEGER)
RETURNS TABLE (access_result INTEGER)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
AS $$
DECLARE
    v_sales_territory VARCHAR(50);
BEGIN
    -- Check if user is db_owner equivalent (admin role)
    IF pg_has_role(current_user, 'wwi_admin', 'MEMBER') THEN
        RETURN QUERY SELECT 1;
        RETURN;
    END IF;
    
    -- Get the sales territory for the given city
    SELECT sp.sales_territory INTO v_sales_territory
    FROM application.cities c
    JOIN application.state_provinces sp ON c.state_province_id = sp.state_province_id
    WHERE c.city_id = p_city_id;
    
    -- Check if user is a member of the territory's sales role
    IF v_sales_territory IS NOT NULL THEN
        BEGIN
            IF pg_has_role(current_user, v_sales_territory || ' Sales', 'MEMBER') THEN
                RETURN QUERY SELECT 1;
                RETURN;
            END IF;
        EXCEPTION WHEN undefined_object THEN
            -- Role doesn't exist, continue checking
            NULL;
        END;
    END IF;
    
    -- Check for Website/WebApi user with session context
    IF session_user IN ('website', 'webapi') THEN
        IF EXISTS (
            SELECT 1 
            FROM application.cities c
            JOIN application.state_provinces sp ON c.state_province_id = sp.state_province_id
            WHERE c.city_id = p_city_id
            AND sp.sales_territory = COALESCE(current_setting('app.sales_territory', true), '')
        ) THEN
            RETURN QUERY SELECT 1;
            RETURN;
        END IF;
    END IF;
    
    -- No access - return empty result set
    RETURN;
END;
$$;

COMMENT ON FUNCTION application.determine_customer_access_tvf IS 'RLS predicate function (table-valued version) for SQL Server compatibility';
