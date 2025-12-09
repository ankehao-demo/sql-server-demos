-- PostgreSQL equivalent of [Application].Configuration_PrepareForAzureStandard
-- Converted from T-SQL to PL/pgSQL
-- Note: This removes features not suitable for basic/standard tier deployments

CREATE OR REPLACE PROCEDURE application.configuration_prepare_for_azure_standard()
LANGUAGE plpgsql
AS $$
BEGIN
    -- Remove advanced features for standard tier compatibility
    -- In PostgreSQL/Azure Database for PostgreSQL, this might be used
    -- to reduce resource usage on lower-tier instances
    
    CALL application.configuration_remove_columnstore_indexing();
    
    CALL application.configuration_disable_in_memory();
    
    RAISE NOTICE 'Database prepared for standard tier deployment';
END;
$$;

COMMENT ON PROCEDURE application.configuration_prepare_for_azure_standard IS 'Removes advanced features for standard tier deployment';
