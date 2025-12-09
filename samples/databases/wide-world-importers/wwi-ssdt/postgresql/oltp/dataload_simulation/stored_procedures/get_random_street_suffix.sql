-- PostgreSQL equivalent of [DataLoadSimulation].GetRandomStreetSuffix
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE PROCEDURE dataload_simulation.get_random_street_suffix(
    INOUT p_random_street_suffix VARCHAR(20)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_street_suffixes TEXT[] := ARRAY[
        'Street', 'Avenue', 'Boulevard', 'Drive', 'Lane', 'Road', 'Way',
        'Place', 'Court', 'Circle', 'Trail', 'Parkway', 'Commons', 'Square',
        'Terrace', 'Loop', 'Alley', 'Path', 'Pike', 'Highway'
    ];
BEGIN
    p_random_street_suffix := v_street_suffixes[FLOOR(RANDOM() * array_length(v_street_suffixes, 1) + 1)::INTEGER];
END;
$$;

COMMENT ON PROCEDURE dataload_simulation.get_random_street_suffix IS 'Selects a random street suffix';
