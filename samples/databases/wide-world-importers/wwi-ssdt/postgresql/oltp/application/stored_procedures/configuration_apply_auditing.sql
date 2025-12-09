-- PostgreSQL equivalent of [Application].Configuration_ApplyAuditing
-- Converted from T-SQL to PL/pgSQL
-- Note: PostgreSQL uses pgaudit extension for auditing instead of SQL Server Audit

CREATE OR REPLACE PROCEDURE application.configuration_apply_auditing()
LANGUAGE plpgsql
AS $$
DECLARE
    v_pgaudit_installed BOOLEAN;
BEGIN
    BEGIN
        -- Check if pgaudit extension is available
        SELECT EXISTS (
            SELECT 1 FROM pg_available_extensions WHERE name = 'pgaudit'
        ) INTO v_pgaudit_installed;
        
        IF NOT v_pgaudit_installed THEN
            RAISE NOTICE 'Warning: pgaudit extension is not available. Auditing cannot be configured.';
            RAISE NOTICE 'To enable auditing, install pgaudit extension and configure postgresql.conf';
            RETURN;
        END IF;
        
        -- Create pgaudit extension if not exists
        CREATE EXTENSION IF NOT EXISTS pgaudit;
        
        -- Configure audit logging for specific tables
        -- Note: pgaudit configuration is typically done in postgresql.conf
        -- These are example settings that would need to be applied at the server level:
        -- pgaudit.log = 'read, write, ddl'
        -- pgaudit.log_catalog = off
        -- pgaudit.log_relation = on
        
        -- Create audit role for object-level auditing
        IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'wwi_auditor') THEN
            CREATE ROLE wwi_auditor NOLOGIN;
        END IF;
        
        -- Grant SELECT on sensitive tables to audit role for object auditing
        GRANT SELECT ON sales.customer_transactions TO wwi_auditor;
        GRANT SELECT ON purchasing.supplier_transactions TO wwi_auditor;
        
        RAISE NOTICE 'Audit configuration prepared.';
        RAISE NOTICE 'For full auditing, configure pgaudit in postgresql.conf:';
        RAISE NOTICE '  pgaudit.role = ''wwi_auditor''';
        RAISE NOTICE '  pgaudit.log = ''read, write, ddl''';
        
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Unable to apply audit configuration';
        RAISE;
    END;
END;
$$;

COMMENT ON PROCEDURE application.configuration_apply_auditing IS 'Configures pgaudit extension for database auditing (PostgreSQL equivalent of SQL Server Audit)';
