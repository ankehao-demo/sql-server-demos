-- PostgreSQL equivalent of [DataLoadSimulation].GetRandomSecondaryAddress
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE PROCEDURE dataload_simulation.get_random_secondary_address(
    INOUT p_random_secondary_address VARCHAR(60)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_secondary_types TEXT[] := ARRAY[
        'Suite', 'Apt', 'Unit', 'Floor', 'Building', 'Room', 'Office', 'Dept'
    ];
    v_type_index INTEGER;
    v_number INTEGER;
BEGIN
    -- 70% chance of having a secondary address
    IF RANDOM() < 0.7 THEN
        v_type_index := FLOOR(RANDOM() * array_length(v_secondary_types, 1) + 1)::INTEGER;
        v_number := FLOOR(RANDOM() * 999 + 1)::INTEGER;
        p_random_secondary_address := v_secondary_types[v_type_index] || ' ' || v_number::TEXT;
    ELSE
        p_random_secondary_address := NULL;
    END IF;
END;
$$;

COMMENT ON PROCEDURE dataload_simulation.get_random_secondary_address IS 'Generates a random secondary address (suite, apt, etc.)';
