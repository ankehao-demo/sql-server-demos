-- PostgreSQL equivalent of [WebApi].InsertStateProvincesFromJson
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE FUNCTION webapi.insert_state_provinces_from_json(
    p_state_provinces JSONB,
    p_user_id INTEGER
)
RETURNS TABLE (state_province_id INTEGER)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    INSERT INTO application.state_provinces(
        state_province_code, state_province_name, country_id, sales_territory,
        latest_recorded_population, last_edited_by
    )
    SELECT 
        (item->>'StateProvinceCode')::VARCHAR(5),
        (item->>'StateProvinceName')::VARCHAR(50),
        (item->>'CountryID')::INTEGER,
        (item->>'SalesTerritory')::VARCHAR(50),
        (item->>'LatestRecordedPopulation')::BIGINT,
        p_user_id
    FROM jsonb_array_elements(p_state_provinces) AS item
    RETURNING application.state_provinces.state_province_id;
END;
$$;

COMMENT ON FUNCTION webapi.insert_state_provinces_from_json IS 'Inserts state provinces from JSON array and returns inserted IDs';
