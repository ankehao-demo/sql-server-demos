-- PostgreSQL equivalent of [Integration].GetCityUpdates
-- Converted from T-SQL to PL/pgSQL
-- Note: SQL Server's FOR SYSTEM_TIME AS OF is converted to use history tables

CREATE OR REPLACE FUNCTION integration.get_city_updates(
    p_last_cutoff TIMESTAMP,
    p_new_cutoff TIMESTAMP
)
RETURNS TABLE (
    wwi_city_id INTEGER,
    city VARCHAR(50),
    state_province VARCHAR(50),
    country VARCHAR(50),
    continent VARCHAR(30),
    sales_territory VARCHAR(50),
    region VARCHAR(30),
    subregion VARCHAR(30),
    location TEXT,
    latest_recorded_population BIGINT,
    valid_from TIMESTAMP,
    valid_to TIMESTAMP
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_end_of_time TIMESTAMP := '9999-12-31 23:59:59.999999'::TIMESTAMP;
    v_initial_load_date DATE := '2020-01-01'::DATE;
BEGIN
    -- Create temporary table for city changes
    CREATE TEMP TABLE temp_city_changes (
        wwi_city_id INTEGER,
        city VARCHAR(50),
        state_province VARCHAR(50),
        country VARCHAR(50),
        continent VARCHAR(30),
        sales_territory VARCHAR(50),
        region VARCHAR(30),
        subregion VARCHAR(30),
        location TEXT,
        latest_recorded_population BIGINT,
        valid_from TIMESTAMP,
        valid_to TIMESTAMP
    ) ON COMMIT DROP;
    
    -- Find country changes from archive and current tables
    INSERT INTO temp_city_changes
    SELECT c.city_id, c.city_name, sp.state_province_name, co.country_name, 
           co.continent, sp.sales_territory, co.region, co.subregion,
           ST_AsText(c.location), COALESCE(c.latest_recorded_population, 0),
           co.valid_from, NULL::TIMESTAMP
    FROM application.countries_archive co
    JOIN application.state_provinces sp ON sp.country_id = co.country_id
    JOIN application.cities c ON c.state_province_id = sp.state_province_id
    WHERE co.valid_from > p_last_cutoff
    AND co.valid_from <= p_new_cutoff
    AND co.valid_from::DATE <> v_initial_load_date;
    
    INSERT INTO temp_city_changes
    SELECT c.city_id, c.city_name, sp.state_province_name, co.country_name, 
           co.continent, sp.sales_territory, co.region, co.subregion,
           ST_AsText(c.location), COALESCE(c.latest_recorded_population, 0),
           co.valid_from, NULL::TIMESTAMP
    FROM application.countries co
    JOIN application.state_provinces sp ON sp.country_id = co.country_id
    JOIN application.cities c ON c.state_province_id = sp.state_province_id
    WHERE co.valid_from > p_last_cutoff
    AND co.valid_from <= p_new_cutoff
    AND co.valid_from::DATE <> v_initial_load_date;
    
    -- Find state province changes
    INSERT INTO temp_city_changes
    SELECT c.city_id, c.city_name, sp.state_province_name, co.country_name, 
           co.continent, sp.sales_territory, co.region, co.subregion,
           ST_AsText(c.location), COALESCE(c.latest_recorded_population, 0),
           sp.valid_from, NULL::TIMESTAMP
    FROM application.state_provinces_archive sp
    JOIN application.countries co ON sp.country_id = co.country_id
    JOIN application.cities c ON c.state_province_id = sp.state_province_id
    WHERE sp.valid_from > p_last_cutoff
    AND sp.valid_from <= p_new_cutoff
    AND sp.valid_from::DATE <> v_initial_load_date;
    
    INSERT INTO temp_city_changes
    SELECT c.city_id, c.city_name, sp.state_province_name, co.country_name, 
           co.continent, sp.sales_territory, co.region, co.subregion,
           ST_AsText(c.location), COALESCE(c.latest_recorded_population, 0),
           sp.valid_from, NULL::TIMESTAMP
    FROM application.state_provinces sp
    JOIN application.countries co ON sp.country_id = co.country_id
    JOIN application.cities c ON c.state_province_id = sp.state_province_id
    WHERE sp.valid_from > p_last_cutoff
    AND sp.valid_from <= p_new_cutoff
    AND sp.valid_from::DATE <> v_initial_load_date;
    
    -- Find city changes
    INSERT INTO temp_city_changes
    SELECT c.city_id, c.city_name, sp.state_province_name, co.country_name, 
           co.continent, sp.sales_territory, co.region, co.subregion,
           ST_AsText(c.location), COALESCE(c.latest_recorded_population, 0),
           c.valid_from, NULL::TIMESTAMP
    FROM application.cities_archive c
    JOIN application.state_provinces sp ON c.state_province_id = sp.state_province_id
    JOIN application.countries co ON sp.country_id = co.country_id
    WHERE c.valid_from > p_last_cutoff
    AND c.valid_from <= p_new_cutoff;
    
    INSERT INTO temp_city_changes
    SELECT c.city_id, c.city_name, sp.state_province_name, co.country_name, 
           co.continent, sp.sales_territory, co.region, co.subregion,
           ST_AsText(c.location), COALESCE(c.latest_recorded_population, 0),
           c.valid_from, NULL::TIMESTAMP
    FROM application.cities c
    JOIN application.state_provinces sp ON c.state_province_id = sp.state_province_id
    JOIN application.countries co ON sp.country_id = co.country_id
    WHERE c.valid_from > p_last_cutoff
    AND c.valid_from <= p_new_cutoff;
    
    -- Create index for faster lookups
    CREATE INDEX ON temp_city_changes (wwi_city_id, valid_from);
    
    -- Calculate valid_to values
    UPDATE temp_city_changes cc
    SET valid_to = COALESCE(
        (SELECT MIN(cc2.valid_from) 
         FROM temp_city_changes cc2
         WHERE cc2.wwi_city_id = cc.wwi_city_id
         AND cc2.valid_from > cc.valid_from),
        v_end_of_time
    );
    
    -- Return results
    RETURN QUERY
    SELECT cc.wwi_city_id, cc.city, cc.state_province, cc.country, 
           cc.continent, cc.sales_territory, cc.region, cc.subregion,
           cc.location, cc.latest_recorded_population, cc.valid_from, cc.valid_to
    FROM temp_city_changes cc
    ORDER BY cc.valid_from;
END;
$$;

COMMENT ON FUNCTION integration.get_city_updates IS 'Returns city dimension updates for ETL processing';
