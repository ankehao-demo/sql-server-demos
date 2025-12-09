-- PostgreSQL equivalent of [DataLoadSimulation].PopulateColdRoomTemperatures_temp
-- Converted from T-SQL to PL/pgSQL
-- This is a temporary/helper procedure for populating cold room temperatures

CREATE OR REPLACE PROCEDURE dataload_simulation.populate_cold_room_temperatures_temp(
    p_number_of_sensors INTEGER DEFAULT 40,
    p_start_date TIMESTAMP DEFAULT '2021-12-20'::TIMESTAMP,
    p_end_date TIMESTAMP DEFAULT NOW()
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_current_date TIMESTAMP;
    v_sensor_number INTEGER;
    v_temperature DECIMAL(18,2);
BEGIN
    v_current_date := p_start_date;
    
    WHILE v_current_date <= p_end_date LOOP
        v_sensor_number := 1;
        WHILE v_sensor_number <= p_number_of_sensors LOOP
            -- Generate temperature (typically between 2 and 6 degrees for cold room)
            v_temperature := ROUND((2 + RANDOM() * 4)::DECIMAL(18,2), 2);
            
            -- Upsert temperature reading
            INSERT INTO warehouse.cold_room_temperatures (
                cold_room_sensor_number, recorded_when, temperature
            )
            VALUES (
                v_sensor_number, v_current_date, v_temperature
            )
            ON CONFLICT (cold_room_sensor_number) 
            DO UPDATE SET 
                recorded_when = EXCLUDED.recorded_when,
                temperature = EXCLUDED.temperature;
            
            v_sensor_number := v_sensor_number + 1;
        END LOOP;
        
        -- Move to next hour
        v_current_date := v_current_date + INTERVAL '1 hour';
    END LOOP;
    
    RAISE NOTICE 'Cold room temperatures populated from % to %', p_start_date, p_end_date;
END;
$$;

COMMENT ON PROCEDURE dataload_simulation.populate_cold_room_temperatures_temp IS 'Populates cold room temperature data for a date range';
