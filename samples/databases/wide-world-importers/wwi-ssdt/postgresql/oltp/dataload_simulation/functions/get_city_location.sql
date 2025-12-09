-- PostgreSQL equivalent of [DataLoadSimulation].GetCityLocation
-- Converted from T-SQL to PL/pgSQL
-- Note: Returns geography point as text since PostgreSQL uses PostGIS for geography

CREATE OR REPLACE FUNCTION dataload_simulation.get_city_location(
    p_city_id INTEGER
)
RETURNS TEXT
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    v_location TEXT;
BEGIN
    -- Get the city location as WKT (Well-Known Text)
    -- In PostgreSQL with PostGIS, this would be ST_AsText(location)
    SELECT ST_AsText(location) INTO v_location
    FROM application.cities
    WHERE city_id = p_city_id
    AND valid_to = '9999-12-31 23:59:59.999999'::TIMESTAMP
    LIMIT 1;
    
    RETURN v_location;
EXCEPTION WHEN undefined_function THEN
    -- PostGIS not installed, return NULL
    RETURN NULL;
END;
$$;

COMMENT ON FUNCTION dataload_simulation.get_city_location IS 'Returns the geographic location of a city as WKT';
