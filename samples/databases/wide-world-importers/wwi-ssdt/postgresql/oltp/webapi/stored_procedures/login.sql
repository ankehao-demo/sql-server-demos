-- PostgreSQL equivalent of [WebApi].Login
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE FUNCTION webapi.login(
    p_logon_name VARCHAR(256),
    p_password VARCHAR(256)
)
RETURNS TABLE (
    person_id INTEGER,
    preferred_name VARCHAR(50),
    is_salesperson BOOLEAN,
    is_employee BOOLEAN,
    territory VARCHAR(50)
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT p.person_id, p.preferred_name, p.is_salesperson, p.is_employee,
           (p.custom_fields->>'PrimarySalesTerritory')::VARCHAR(50)
    FROM application.people p
    WHERE p.is_permitted_to_logon = true
    AND p.logon_name = p_logon_name;
END;
$$;

COMMENT ON FUNCTION webapi.login IS 'Authenticates a user and returns their profile information';
