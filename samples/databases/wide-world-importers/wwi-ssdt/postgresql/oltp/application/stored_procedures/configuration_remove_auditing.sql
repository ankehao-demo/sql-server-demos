-- PostgreSQL equivalent of [Application].Configuration_RemoveAuditing
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE PROCEDURE application.configuration_remove_auditing()
LANGUAGE plpgsql
AS $$
BEGIN
    BEGIN
        -- Revoke audit permissions from audit role
        REVOKE SELECT ON sales.customer_transactions FROM wwi_auditor;
        REVOKE SELECT ON purchasing.supplier_transactions FROM wwi_auditor;
        
        -- Drop audit role if exists
        DROP ROLE IF EXISTS wwi_auditor;
        
        -- Note: pgaudit extension removal and configuration changes
        -- need to be done at the server level in postgresql.conf
        
        RAISE NOTICE 'Audit role and permissions removed.';
        RAISE NOTICE 'To fully disable auditing, update postgresql.conf and remove pgaudit settings.';
        
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Unable to remove audit configuration';
        RAISE;
    END;
END;
$$;

COMMENT ON PROCEDURE application.configuration_remove_auditing IS 'Removes pgaudit configuration (PostgreSQL equivalent of removing SQL Server Audit)';
