-- PostgreSQL equivalent of [WebApi].InsertCitiesFromJson
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE FUNCTION webapi.insert_cities_from_json(
    p_cities JSONB,
    p_user_id INTEGER
)
RETURNS TABLE (city_id INTEGER)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    INSERT INTO application.cities(city_name, state_province_id, latest_recorded_population, last_edited_by)
    SELECT 
        (item->>'CityName')::VARCHAR(50),
        (item->>'StateProvinceID')::INTEGER,
        (item->>'LatestRecordedPopulation')::BIGINT,
        p_user_id
    FROM jsonb_array_elements(p_cities) AS item
    RETURNING application.cities.city_id;
END;
$$;

COMMENT ON FUNCTION webapi.insert_cities_from_json IS 'Inserts cities from JSON array and returns inserted IDs';
