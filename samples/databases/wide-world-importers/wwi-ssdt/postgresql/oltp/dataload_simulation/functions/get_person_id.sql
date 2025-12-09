-- PostgreSQL equivalent of [DataLoadSimulation].GetPersonID
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE FUNCTION dataload_simulation.get_person_id(
    p_full_name VARCHAR(50)
)
RETURNS INTEGER
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    v_person_id INTEGER;
BEGIN
    SELECT person_id INTO v_person_id
    FROM application.people
    WHERE full_name = p_full_name
    AND valid_to = '9999-12-31 23:59:59.999999'::TIMESTAMP
    LIMIT 1;
    
    RETURN v_person_id;
END;
$$;

COMMENT ON FUNCTION dataload_simulation.get_person_id IS 'Returns the person ID for a given full name';
