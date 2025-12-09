-- PostgreSQL equivalent of [Application].Configuration_DisableInMemory
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE PROCEDURE application.configuration_disable_in_memory()
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    BEGIN
        -- Drop the high-performance table alternatives
        DROP TABLE IF EXISTS warehouse.vehicle_temperatures_fast CASCADE;
        
        -- Drop the composite types (table-valued parameter equivalents)
        DROP TYPE IF EXISTS website.order_id_list CASCADE;
        DROP TYPE IF EXISTS website.order_list CASCADE;
        DROP TYPE IF EXISTS website.order_line_list CASCADE;
        DROP TYPE IF EXISTS website.sensor_data_list CASCADE;
        
        RAISE NOTICE 'In-memory alternatives successfully disabled';
        
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Unable to disable in-memory alternatives: %', SQLERRM;
        RAISE;
    END;
END;
$$;

COMMENT ON PROCEDURE application.configuration_disable_in_memory IS 'Removes high-performance table alternatives';
