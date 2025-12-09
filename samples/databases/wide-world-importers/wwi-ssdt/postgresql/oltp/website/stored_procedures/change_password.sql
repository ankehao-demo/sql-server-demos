-- PostgreSQL equivalent of [Website].ChangePassword
-- Converted from T-SQL to PL/pgSQL
-- Requires pgcrypto extension for digest() function

CREATE OR REPLACE PROCEDURE website.change_password(
    p_person_id INTEGER,
    p_old_password VARCHAR(40),
    p_new_password VARCHAR(40)
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_rows_affected INTEGER;
BEGIN
    -- Update password if old password matches
    UPDATE application.people
    SET is_permitted_to_logon = true,
        hashed_password = digest(p_new_password || full_name, 'sha256')
    WHERE person_id = p_person_id
    AND person_id <> 1
    AND hashed_password = digest(p_old_password || full_name, 'sha256');
    
    GET DIAGNOSTICS v_rows_affected = ROW_COUNT;
    
    IF v_rows_affected = 0 THEN
        RAISE NOTICE 'The PersonID must be valid, and the old password must be valid.';
        RAISE NOTICE 'If the user has also changed name, please contact the IT staff to assist.';
        RAISE EXCEPTION 'Invalid Password Change' USING ERRCODE = '51000';
    END IF;
END;
$$;

COMMENT ON PROCEDURE website.change_password IS 'Changes password for a person after validating old password';
