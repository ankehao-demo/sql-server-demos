-- PostgreSQL equivalent of [DataLoadSimulation].GetRandomStreet
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE PROCEDURE dataload_simulation.get_random_street(
    INOUT p_random_street VARCHAR(100)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_street_number INTEGER;
    v_street_name VARCHAR(50);
    v_street_suffix VARCHAR(20);
BEGIN
    -- Generate a random street number
    v_street_number := FLOOR(RANDOM() * 9999 + 1)::INTEGER;
    
    -- Get random street name
    CALL dataload_simulation.get_random_street_name(v_street_name);
    
    -- Get random street suffix
    CALL dataload_simulation.get_random_street_suffix(v_street_suffix);
    
    -- Combine into full street address
    p_random_street := v_street_number::TEXT || ' ' || v_street_name || ' ' || v_street_suffix;
END;
$$;

COMMENT ON PROCEDURE dataload_simulation.get_random_street IS 'Generates a random street address';
