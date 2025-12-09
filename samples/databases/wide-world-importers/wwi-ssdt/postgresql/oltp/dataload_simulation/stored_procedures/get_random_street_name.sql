-- PostgreSQL equivalent of [DataLoadSimulation].GetRandomStreetName
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE PROCEDURE dataload_simulation.get_random_street_name(
    INOUT p_random_street_name VARCHAR(50)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_street_names TEXT[] := ARRAY[
        'Main', 'Oak', 'Pine', 'Maple', 'Cedar', 'Elm', 'Washington', 'Lake',
        'Hill', 'Park', 'Church', 'Mill', 'River', 'Market', 'Union', 'Spring',
        'High', 'Center', 'School', 'North', 'South', 'East', 'West', 'First',
        'Second', 'Third', 'Fourth', 'Fifth', 'Sixth', 'Seventh', 'Eighth',
        'Walnut', 'Chestnut', 'Broad', 'Pleasant', 'Franklin', 'Jefferson',
        'Lincoln', 'Madison', 'Jackson', 'Adams', 'Monroe', 'Wilson', 'Taylor'
    ];
BEGIN
    p_random_street_name := v_street_names[FLOOR(RANDOM() * array_length(v_street_names, 1) + 1)::INTEGER];
END;
$$;

COMMENT ON PROCEDURE dataload_simulation.get_random_street_name IS 'Selects a random street name';
