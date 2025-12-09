-- PostgreSQL equivalent of [Website].RecordVehicleTemperature
-- Converted from T-SQL to PL/pgSQL
-- Uses jsonb_to_recordset instead of OPENJSON

CREATE OR REPLACE PROCEDURE website.record_vehicle_temperature(
    p_full_sensor_data_array TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_crlf TEXT := E'\r\n';
    v_help_message TEXT;
    v_json_data JSONB;
    v_rows_affected INTEGER;
BEGIN
    v_help_message := 'JSON sensor data is invalid. An example of what is required is as follows:' || v_crlf || v_crlf
        || '{"Recordings":' || v_crlf
        || '    [' || v_crlf
        || '        {"type":"Feature", "geometry": {"type":"Point", "coordinates":[-89.7600464,50.4742420] }, "properties":{"rego":"WWI-321-A","sensor":1,"when":"2016-01-01T07:00:00","temp":3.96}},' || v_crlf
        || '        {"type":"Feature", "geometry": {"type":"Point", "coordinates":[-89.7600464,50.4742420] }, "properties":{"rego":"WWI-321-A","sensor":2,"when":"2016-01-01T07:00:00","temp":3.98}}' || v_crlf
        || '    ]' || v_crlf
        || '}';
    
    -- Validate JSON
    BEGIN
        v_json_data := p_full_sensor_data_array::JSONB;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '%', v_help_message;
        RAISE EXCEPTION 'FullSensorDataArray must be valid JSON data' USING ERRCODE = '51000';
    END;
    
    BEGIN
        -- Insert vehicle temperatures from JSON
        INSERT INTO warehouse.vehicle_temperatures (
            vehicle_registration, chiller_sensor_number, recorded_when, temperature,
            full_sensor_data, is_compressed, compressed_sensor_data
        )
        SELECT 
            r.properties->>'rego' AS vehicle_registration,
            (r.properties->>'sensor')::INTEGER AS chiller_sensor_number,
            (r.properties->>'when')::TIMESTAMP AS recorded_when,
            (r.properties->>'temp')::DECIMAL(18,2) AS temperature,
            r.recording::TEXT AS full_sensor_data,
            false AS is_compressed,
            NULL AS compressed_sensor_data
        FROM jsonb_array_elements(v_json_data->'Recordings') AS r(recording),
             LATERAL (SELECT r.recording AS properties_obj) sub,
             LATERAL (SELECT r.recording->'properties' AS properties) props;
        
        GET DIAGNOSTICS v_rows_affected = ROW_COUNT;
        
        IF v_rows_affected = 0 THEN
            RAISE NOTICE 'Warning: No valid sensor data found';
            RAISE NOTICE '%', v_help_message;
        END IF;
        
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '%', v_help_message;
        RAISE EXCEPTION 'Valid JSON was supplied but does not match the temperature recordings array structure' 
            USING ERRCODE = '51000';
    END;
END;
$$;

COMMENT ON PROCEDURE website.record_vehicle_temperature IS 'Records vehicle temperature sensor readings from GeoJSON input';

-- Simplified version with cleaner JSON parsing
CREATE OR REPLACE PROCEDURE website.record_vehicle_temperature_v2(
    p_full_sensor_data_array JSONB
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_rows_affected INTEGER;
BEGIN
    BEGIN
        -- Insert vehicle temperatures from JSON
        INSERT INTO warehouse.vehicle_temperatures (
            vehicle_registration, chiller_sensor_number, recorded_when, temperature,
            full_sensor_data, is_compressed, compressed_sensor_data
        )
        SELECT 
            recording->'properties'->>'rego',
            (recording->'properties'->>'sensor')::INTEGER,
            (recording->'properties'->>'when')::TIMESTAMP,
            (recording->'properties'->>'temp')::DECIMAL(18,2),
            recording::TEXT,
            false,
            NULL
        FROM jsonb_array_elements(p_full_sensor_data_array->'Recordings') AS recording;
        
        GET DIAGNOSTICS v_rows_affected = ROW_COUNT;
        
        IF v_rows_affected = 0 THEN
            RAISE NOTICE 'Warning: No valid sensor data found';
        END IF;
        
    EXCEPTION WHEN OTHERS THEN
        RAISE EXCEPTION 'Unable to process vehicle temperature data: %', SQLERRM 
            USING ERRCODE = '51000';
    END;
END;
$$;

COMMENT ON PROCEDURE website.record_vehicle_temperature_v2 IS 'Records vehicle temperature sensor readings from GeoJSON input (JSONB version)';
