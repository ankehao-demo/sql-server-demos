-- PostgreSQL equivalent of [WebApi].InsertCountriesFromJson
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE FUNCTION webapi.insert_countries_from_json(
    p_countries JSONB,
    p_user_id INTEGER
)
RETURNS TABLE (country_id INTEGER)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    INSERT INTO application.countries(country_name, formal_name, iso_alpha3_code, iso_numeric_code, 
                                       country_type, latest_recorded_population, continent, region, 
                                       subregion, last_edited_by)
    SELECT 
        (item->>'CountryName')::VARCHAR(60),
        (item->>'FormalName')::VARCHAR(60),
        (item->>'IsoAlpha3Code')::CHAR(3),
        (item->>'IsoNumericCode')::INTEGER,
        (item->>'CountryType')::VARCHAR(20),
        (item->>'LatestRecordedPopulation')::BIGINT,
        (item->>'Continent')::VARCHAR(30),
        (item->>'Region')::VARCHAR(30),
        (item->>'Subregion')::VARCHAR(30),
        p_user_id
    FROM jsonb_array_elements(p_countries) AS item
    RETURNING application.countries.country_id;
END;
$$;

COMMENT ON FUNCTION webapi.insert_countries_from_json IS 'Inserts countries from JSON array and returns inserted IDs';
