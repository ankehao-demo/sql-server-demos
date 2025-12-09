-- PostgreSQL equivalent of [WebApi].UpdateCountryFromJson
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE PROCEDURE webapi.update_country_from_json(
    p_country JSONB,
    p_country_id INTEGER,
    p_user_id INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE application.countries SET
        country_name = COALESCE((p_country->>'CountryName')::VARCHAR(60), country_name),
        formal_name = COALESCE((p_country->>'FormalName')::VARCHAR(60), formal_name),
        iso_alpha3_code = COALESCE((p_country->>'IsoAlpha3Code')::CHAR(3), iso_alpha3_code),
        iso_numeric_code = COALESCE((p_country->>'IsoNumericCode')::INTEGER, iso_numeric_code),
        country_type = COALESCE((p_country->>'CountryType')::VARCHAR(20), country_type),
        latest_recorded_population = (p_country->>'LatestRecordedPopulation')::BIGINT,
        continent = COALESCE((p_country->>'Continent')::VARCHAR(30), continent),
        region = COALESCE((p_country->>'Region')::VARCHAR(30), region),
        subregion = COALESCE((p_country->>'Subregion')::VARCHAR(30), subregion),
        last_edited_by = p_user_id
    WHERE country_id = p_country_id;
END;
$$;

COMMENT ON PROCEDURE webapi.update_country_from_json IS 'Updates a country from JSON';
