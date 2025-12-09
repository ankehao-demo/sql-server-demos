-- PostgreSQL equivalent of [DataLoadSimulation].RecordDeliveryVanTemperatures
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE PROCEDURE dataload_simulation.record_delivery_van_temperatures(
    p_number_of_readings INTEGER,
    p_number_of_sensors INTEGER,
    p_current_date_time TIMESTAMP,
    p_starting_when TIMESTAMP,
    p_is_silent_mode BOOLEAN
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_counter INTEGER := 0;
    v_sensor_counter INTEGER;
    v_vehicle_registration VARCHAR(20);
    v_recorded_when TIMESTAMP;
    v_temperature DECIMAL(18,2);
    v_full_sensor_data TEXT;
BEGIN
    -- Generate temperature readings for delivery vans
    WHILE v_counter < p_number_of_readings LOOP
        -- Generate a random vehicle registration
        v_vehicle_registration := 'WWI-' || LPAD(FLOOR(RANDOM() * 999 + 1)::TEXT, 3, '0') || '-' || CHR(65 + FLOOR(RANDOM() * 26)::INTEGER);
        
        -- Generate readings for each sensor on the vehicle
        v_sensor_counter := 1;
        WHILE v_sensor_counter <= p_number_of_sensors LOOP
            -- Calculate recorded time (spread throughout the day)
            v_recorded_when := p_starting_when + (v_counter * INTERVAL '1 minute');
            
            -- Generate temperature (typically between -5 and 10 degrees for chiller)
            v_temperature := ROUND((-5 + RANDOM() * 15)::DECIMAL(18,2), 2);
            
            -- Generate full sensor data JSON
            v_full_sensor_data := jsonb_build_object(
                'type', 'Feature',
                'geometry', jsonb_build_object(
                    'type', 'Point',
                    'coordinates', ARRAY[
                        ROUND((-90 + RANDOM() * 10)::DECIMAL(10,7), 7),
                        ROUND((40 + RANDOM() * 10)::DECIMAL(10,7), 7)
                    ]
                ),
                'properties', jsonb_build_object(
                    'rego', v_vehicle_registration,
                    'sensor', v_sensor_counter,
                    'when', to_char(v_recorded_when, 'YYYY-MM-DD"T"HH24:MI:SS'),
                    'temp', v_temperature
                )
            )::TEXT;
            
            -- Insert temperature reading
            INSERT INTO warehouse.vehicle_temperatures (
                vehicle_registration, chiller_sensor_number, recorded_when,
                temperature, full_sensor_data, is_compressed, compressed_sensor_data
            )
            VALUES (
                v_vehicle_registration, v_sensor_counter, v_recorded_when,
                v_temperature, v_full_sensor_data, false, NULL
            );
            
            v_sensor_counter := v_sensor_counter + 1;
        END LOOP;
        
        v_counter := v_counter + 1;
    END LOOP;
END;
$$;

COMMENT ON PROCEDURE dataload_simulation.record_delivery_van_temperatures IS 'Simulates recording of delivery van temperature sensor readings';
