-- Phase 3: OLTP Code Migration - Application Schema Functions
-- Converted from SQL Server T-SQL to PostgreSQL PL/pgSQL

-- =============================================
-- Function: Application.DetermineCustomerAccess
-- Description: Determines if the current user has access to a customer based on city
-- Used for Row-Level Security
-- =============================================
CREATE OR REPLACE FUNCTION application.determine_customer_access(p_city_id integer)
RETURNS TABLE (access_result integer)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_sales_territory varchar(50);
    v_session_territory varchar(50);
BEGIN
    -- Check if user is db_owner equivalent (superuser or member of admin role)
    IF pg_has_role(current_user, 'postgres', 'MEMBER') OR 
       pg_has_role(current_user, 'db_owner', 'MEMBER') THEN
        RETURN QUERY SELECT 1;
        RETURN;
    END IF;
    
    -- Get the sales territory for the city
    SELECT sp.salesterritory INTO v_sales_territory
    FROM application.cities AS c
    INNER JOIN application.stateprovinces AS sp
    ON c.stateprovinceid = sp.stateprovinceid
    WHERE c.cityid = p_city_id;
    
    -- Check if user is member of the territory's sales role
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
    
    -- Check for Website or WebApi users with session context
    IF session_user IN ('website', 'webapi', 'Website', 'WebApi') THEN
        BEGIN
            v_session_territory := current_setting('app.sales_territory', true);
            IF v_session_territory IS NOT NULL THEN
                IF EXISTS (
                    SELECT 1
                    FROM application.cities AS c
                    INNER JOIN application.stateprovinces AS sp
                    ON c.stateprovinceid = sp.stateprovinceid
                    WHERE c.cityid = p_city_id
                    AND sp.salesterritory = v_session_territory
                ) THEN
                    RETURN QUERY SELECT 1;
                    RETURN;
                END IF;
            END IF;
        EXCEPTION WHEN OTHERS THEN
            -- Session context not set, continue
            NULL;
        END;
    END IF;
    
    -- No access
    RETURN;
END;
$$;

COMMENT ON FUNCTION application.determine_customer_access(integer) IS 
'Determines if the current user has access to a customer based on city. Used for Row-Level Security.';
