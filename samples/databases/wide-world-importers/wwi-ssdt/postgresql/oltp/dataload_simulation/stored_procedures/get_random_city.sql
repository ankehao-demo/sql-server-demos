-- PostgreSQL equivalent of [DataLoadSimulation].GetRandomCity
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE PROCEDURE dataload_simulation.get_random_city(
    INOUT p_random_city_id INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
    SELECT city_id INTO p_random_city_id
    FROM application.cities
    WHERE valid_to = '9999-12-31 23:59:59.999999'::TIMESTAMP
    ORDER BY RANDOM()
    LIMIT 1;
END;
$$;

COMMENT ON PROCEDURE dataload_simulation.get_random_city IS 'Selects a random city ID';
