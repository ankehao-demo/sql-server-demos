-- PostgreSQL equivalent of [DataLoadSimulation].GetAreaCode
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE FUNCTION dataload_simulation.get_area_code(
    p_state_province_code VARCHAR(4)
)
RETURNS VARCHAR(4)
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    v_area_code VARCHAR(4);
BEGIN
    SELECT ac.area_code INTO v_area_code
    FROM dataload_simulation.area_code ac
    WHERE ac.state_province_code = p_state_province_code
    LIMIT 1;
    
    RETURN v_area_code;
END;
$$;

COMMENT ON FUNCTION dataload_simulation.get_area_code IS 'Retrieves the area code for a state province code';
