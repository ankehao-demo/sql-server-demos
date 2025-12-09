-- PostgreSQL equivalent of [Application].CreateRoleIfNonexistent
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE PROCEDURE application.create_role_if_nonexistent(
    p_role_name VARCHAR(128)
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Check if role exists
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = p_role_name) THEN
        BEGIN
            EXECUTE format('CREATE ROLE %I', p_role_name);
            RAISE NOTICE 'Role % created', p_role_name;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Unable to create role %', p_role_name;
            RAISE;
        END;
    END IF;
END;
$$;

COMMENT ON PROCEDURE application.create_role_if_nonexistent IS 'Creates a database role if it does not already exist';
