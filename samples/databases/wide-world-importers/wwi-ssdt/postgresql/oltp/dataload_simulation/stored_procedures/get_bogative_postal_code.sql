-- PostgreSQL equivalent of [DataLoadSimulation].GetBogativePostalCode
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE PROCEDURE dataload_simulation.get_bogative_postal_code(
    INOUT p_bogative_postal_code VARCHAR(10)
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Generate a random 5-digit postal code
    p_bogative_postal_code := LPAD(FLOOR(RANDOM() * 99999)::TEXT, 5, '0');
END;
$$;

COMMENT ON PROCEDURE dataload_simulation.get_bogative_postal_code IS 'Generates a fictional postal code';
