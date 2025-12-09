-- PostgreSQL equivalent of [DataLoadSimulation].RecordColdRoomTemperatures
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE PROCEDURE dataload_simulation.record_cold_room_temperatures(
    p_number_of_readings INTEGER,
    p_number_of_sensors INTEGER,
    p_current_date_time TIMESTAMP,
    p_end_of_time TIMESTAMP,
    p_is_silent_mode BOOLEAN
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_counter INTEGER := 0;
    v_sensor_number INTEGER;
    v_recorded_when TIMESTAMP;
    v_temperature DECIMAL(18,2);
    v_readings_per_sensor INTEGER;
BEGIN
    -- Calculate readings per sensor
    v_readings_per_sensor := p_number_of_readings / GREATEST(p_number_of_sensors, 1);
    
    -- Generate temperature readings for cold room sensors
    v_sensor_number := 1;
    WHILE v_sensor_number <= p_number_of_sensors LOOP
        v_counter := 0;
        WHILE v_counter < v_readings_per_sensor LOOP
            -- Calculate recorded time (spread throughout the day)
            v_recorded_when := p_current_date_time + (v_counter * INTERVAL '1 second');
            
            -- Generate temperature (typically between 2 and 6 degrees for cold room)
            v_temperature := ROUND((2 + RANDOM() * 4)::DECIMAL(18,2), 2);
            
            -- Upsert temperature reading (update if sensor exists, insert if not)
            INSERT INTO warehouse.cold_room_temperatures (
                cold_room_sensor_number, recorded_when, temperature
            )
            VALUES (
                v_sensor_number, v_recorded_when, v_temperature
            )
            ON CONFLICT (cold_room_sensor_number) 
            DO UPDATE SET 
                recorded_when = EXCLUDED.recorded_when,
                temperature = EXCLUDED.temperature;
            
            v_counter := v_counter + 1;
        END LOOP;
        
        v_sensor_number := v_sensor_number + 1;
    END LOOP;
END;
$$;

COMMENT ON PROCEDURE dataload_simulation.record_cold_room_temperatures IS 'Simulates recording of cold room temperature sensor readings';
