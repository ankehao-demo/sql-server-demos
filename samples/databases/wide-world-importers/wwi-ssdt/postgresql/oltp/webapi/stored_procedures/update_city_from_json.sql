-- PostgreSQL equivalent of [WebApi].UpdateCityFromJson
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE PROCEDURE webapi.update_city_from_json(
    p_city JSONB,
    p_city_id INTEGER,
    p_user_id INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE application.cities SET
        city_name = (p_city->>'CityName')::VARCHAR(50),
        state_province_id = (p_city->>'StateProvinceID')::INTEGER,
        latest_recorded_population = (p_city->>'LatestRecordedPopulation')::BIGINT,
        last_edited_by = p_user_id
    WHERE city_id = p_city_id;
END;
$$;

COMMENT ON PROCEDURE webapi.update_city_from_json IS 'Updates a city from JSON';
