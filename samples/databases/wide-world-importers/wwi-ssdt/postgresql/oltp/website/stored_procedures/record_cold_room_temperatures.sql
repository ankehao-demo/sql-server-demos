-- PostgreSQL equivalent of [Website].RecordColdRoomTemperatures
-- Converted from T-SQL to PL/pgSQL
-- Note: SQL Server's NATIVE_COMPILATION is not available in PostgreSQL
-- This procedure uses standard PL/pgSQL with upsert (INSERT ON CONFLICT)

-- Create composite type for sensor data if not exists
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'sensor_data_list') THEN
        CREATE TYPE website.sensor_data_list AS (
            sensor_data_list_id INTEGER,
            cold_room_sensor_number INTEGER,
            recorded_when TIMESTAMP,
            temperature DECIMAL(18,2)
        );
    END IF;
END $$;

CREATE OR REPLACE PROCEDURE website.record_cold_room_temperatures(
    p_sensor_readings website.sensor_data_list[]
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_reading RECORD;
BEGIN
    BEGIN
        -- Process each sensor reading using upsert
        FOR v_reading IN SELECT * FROM unnest(p_sensor_readings)
        LOOP
            INSERT INTO warehouse.cold_room_temperatures (
                cold_room_sensor_number, recorded_when, temperature
            )
            VALUES (
                v_reading.cold_room_sensor_number, 
                v_reading.recorded_when, 
                v_reading.temperature
            )
            ON CONFLICT (cold_room_sensor_number) 
            DO UPDATE SET 
                recorded_when = EXCLUDED.recorded_when,
                temperature = EXCLUDED.temperature;
        END LOOP;
        
    EXCEPTION WHEN OTHERS THEN
        RAISE EXCEPTION 'Unable to apply the sensor data' USING ERRCODE = '51000';
    END;
END;
$$;

COMMENT ON PROCEDURE website.record_cold_room_temperatures IS 'Records cold room temperature sensor readings using upsert';

-- Alternative version using JSONB for easier calling from applications
CREATE OR REPLACE PROCEDURE website.record_cold_room_temperatures_json(
    p_sensor_readings JSONB
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_reading RECORD;
BEGIN
    BEGIN
        -- Process each sensor reading using upsert
        FOR v_reading IN 
            SELECT * FROM jsonb_to_recordset(p_sensor_readings) AS x(
                sensor_data_list_id INTEGER,
                cold_room_sensor_number INTEGER,
                recorded_when TIMESTAMP,
                temperature DECIMAL(18,2)
            )
        LOOP
            INSERT INTO warehouse.cold_room_temperatures (
                cold_room_sensor_number, recorded_when, temperature
            )
            VALUES (
                v_reading.cold_room_sensor_number, 
                v_reading.recorded_when, 
                v_reading.temperature
            )
            ON CONFLICT (cold_room_sensor_number) 
            DO UPDATE SET 
                recorded_when = EXCLUDED.recorded_when,
                temperature = EXCLUDED.temperature;
        END LOOP;
        
    EXCEPTION WHEN OTHERS THEN
        RAISE EXCEPTION 'Unable to apply the sensor data' USING ERRCODE = '51000';
    END;
END;
$$;

COMMENT ON PROCEDURE website.record_cold_room_temperatures_json IS 'Records cold room temperature sensor readings using JSONB input';
