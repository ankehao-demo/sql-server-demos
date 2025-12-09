-- PostgreSQL equivalent of [Application].AddRoleMemberIfNonexistent
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE PROCEDURE application.add_role_member_if_nonexistent(
    p_role_name VARCHAR(128),
    p_user_name VARCHAR(128)
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Check if user is already a member of the role
    IF NOT EXISTS (
        SELECT 1 
        FROM pg_auth_members am
        JOIN pg_roles r ON am.roleid = r.oid
        JOIN pg_roles u ON am.member = u.oid
        WHERE r.rolname = p_role_name
        AND u.rolname = p_user_name
    ) THEN
        BEGIN
            EXECUTE format('GRANT %I TO %I', p_role_name, p_user_name);
            RAISE NOTICE 'User % added to role %', p_user_name, p_role_name;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Unable to add user % to role %', p_user_name, p_role_name;
            RAISE;
        END;
    END IF;
END;
$$;

COMMENT ON PROCEDURE application.add_role_member_if_nonexistent IS 'Adds a user to a database role if not already a member';
