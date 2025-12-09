-- PostgreSQL equivalent of [Website].ActivateWebsiteLogon
-- Converted from T-SQL to PL/pgSQL
-- Requires pgcrypto extension for digest() function

CREATE OR REPLACE PROCEDURE website.activate_website_logon(
    p_person_id INTEGER,
    p_logon_name VARCHAR(50),
    p_initial_password VARCHAR(40)
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_rows_affected INTEGER;
    v_full_name VARCHAR(50);
BEGIN
    -- Get the full name for password hashing
    SELECT full_name INTO v_full_name
    FROM application.people
    WHERE person_id = p_person_id;
    
    -- Update the person record to enable logon
    UPDATE application.people
    SET is_permitted_to_logon = true,
        logon_name = p_logon_name,
        hashed_password = digest(p_initial_password || full_name, 'sha256'),
        user_preferences = (SELECT user_preferences FROM application.people WHERE person_id = 1)
    WHERE person_id = p_person_id
    AND person_id <> 1
    AND is_permitted_to_logon = false;
    
    GET DIAGNOSTICS v_rows_affected = ROW_COUNT;
    
    IF v_rows_affected = 0 THEN
        RAISE NOTICE 'The PersonID must be valid, must not be person 1, and must not already be enabled';
        RAISE EXCEPTION 'Invalid PersonID' USING ERRCODE = '51000';
    END IF;
END;
$$;

COMMENT ON PROCEDURE website.activate_website_logon IS 'Activates website logon for a person with initial password';
