-- PostgreSQL equivalent of [WebApi].UpdateStateProvinceFromJson
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE PROCEDURE webapi.update_state_province_from_json(
    p_state_province JSONB,
    p_state_province_id INTEGER,
    p_user_id INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE application.state_provinces SET
        state_province_code = COALESCE((p_state_province->>'StateProvinceCode')::VARCHAR(5), state_province_code),
        state_province_name = COALESCE((p_state_province->>'StateProvinceName')::VARCHAR(50), state_province_name),
        country_id = COALESCE((p_state_province->>'CountryID')::INTEGER, country_id),
        sales_territory = COALESCE((p_state_province->>'SalesTerritory')::VARCHAR(50), sales_territory),
        latest_recorded_population = (p_state_province->>'LatestRecordedPopulation')::BIGINT,
        last_edited_by = p_user_id
    WHERE state_province_id = p_state_province_id;
END;
$$;

COMMENT ON PROCEDURE webapi.update_state_province_from_json IS 'Updates a state/province from JSON';
