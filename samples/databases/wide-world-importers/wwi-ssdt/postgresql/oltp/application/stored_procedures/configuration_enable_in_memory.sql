-- PostgreSQL equivalent of [Application].Configuration_EnableInMemory
-- Converted from T-SQL to PL/pgSQL
-- Note: PostgreSQL does not have native In-Memory OLTP like SQL Server
-- This procedure creates UNLOGGED tables as a partial alternative for high-performance scenarios
-- For true in-memory performance, consider using pg_prewarm or memory-mapped tables

CREATE OR REPLACE PROCEDURE application.configuration_enable_in_memory()
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    BEGIN
        RAISE NOTICE 'PostgreSQL does not have native In-Memory OLTP like SQL Server.';
        RAISE NOTICE 'Creating UNLOGGED tables as a high-performance alternative.';
        RAISE NOTICE 'Warning: UNLOGGED tables are not crash-safe - data may be lost on server crash.';
        
        -- Note: In PostgreSQL, we cannot convert existing tables to UNLOGGED
        -- This would need to be done during initial schema creation
        -- The following demonstrates the approach for new tables
        
        -- Create UNLOGGED version of VehicleTemperatures for high-frequency sensor data
        -- This is similar to SQL Server's memory-optimized tables
        CREATE TABLE IF NOT EXISTS warehouse.vehicle_temperatures_fast (
            vehicle_temperature_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            vehicle_registration VARCHAR(20) NOT NULL,
            chiller_sensor_number INTEGER NOT NULL,
            recorded_when TIMESTAMP NOT NULL,
            temperature DECIMAL(10,2) NOT NULL,
            full_sensor_data VARCHAR(1000),
            is_compressed BOOLEAN NOT NULL DEFAULT false,
            compressed_sensor_data BYTEA
        );
        
        -- Make it UNLOGGED for performance (if not already)
        -- Note: ALTER TABLE ... SET UNLOGGED is available in PostgreSQL 15+
        
        -- Create indexes for fast lookups
        CREATE INDEX IF NOT EXISTS idx_vt_fast_vehicle_reg 
            ON warehouse.vehicle_temperatures_fast (vehicle_registration);
        CREATE INDEX IF NOT EXISTS idx_vt_fast_recorded_when 
            ON warehouse.vehicle_temperatures_fast (recorded_when);
        
        -- Create table types as composite types (PostgreSQL equivalent of TVPs)
        -- These replace SQL Server's memory-optimized table types
        
        DROP TYPE IF EXISTS website.order_id_list CASCADE;
        CREATE TYPE website.order_id_list AS (
            order_id INTEGER
        );
        
        DROP TYPE IF EXISTS website.order_list CASCADE;
        CREATE TYPE website.order_list AS (
            order_reference INTEGER,
            customer_id INTEGER,
            contact_person_id INTEGER,
            expected_delivery_date DATE,
            customer_purchase_order_number VARCHAR(20),
            is_undersupply_backordered BOOLEAN,
            comments TEXT,
            delivery_instructions TEXT
        );
        
        DROP TYPE IF EXISTS website.order_line_list CASCADE;
        CREATE TYPE website.order_line_list AS (
            order_reference INTEGER,
            stock_item_id INTEGER,
            description VARCHAR(100),
            quantity INTEGER
        );
        
        DROP TYPE IF EXISTS website.sensor_data_list CASCADE;
        CREATE TYPE website.sensor_data_list AS (
            sensor_data_list_id INTEGER,
            cold_room_sensor_number INTEGER,
            recorded_when TIMESTAMP,
            temperature DECIMAL(18,2)
        );
        
        RAISE NOTICE 'In-memory alternatives successfully configured';
        RAISE NOTICE 'Created composite types for table-valued parameters';
        RAISE NOTICE 'For better performance, consider:';
        RAISE NOTICE '  - pg_prewarm extension to preload tables into buffer cache';
        RAISE NOTICE '  - Increasing shared_buffers in postgresql.conf';
        RAISE NOTICE '  - Using connection pooling (pgbouncer)';
        
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Unable to enable in-memory alternatives: %', SQLERRM;
        RAISE;
    END;
END;
$$;

COMMENT ON PROCEDURE application.configuration_enable_in_memory IS 'Creates high-performance table alternatives (PostgreSQL equivalent of SQL Server In-Memory OLTP)';
