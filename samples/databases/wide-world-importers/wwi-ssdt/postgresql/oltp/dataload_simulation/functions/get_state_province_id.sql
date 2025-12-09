-- PostgreSQL equivalent of [DataLoadSimulation].GetStateProvinceID
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE FUNCTION dataload_simulation.get_state_province_id(
    p_state_province_code VARCHAR(5)
)
RETURNS INTEGER
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    v_state_province_id INTEGER;
BEGIN
    SELECT state_province_id INTO v_state_province_id
    FROM application.state_provinces
    WHERE state_province_code = p_state_province_code
    AND valid_to = '9999-12-31 23:59:59.999999'::TIMESTAMP
    LIMIT 1;
    
    RETURN v_state_province_id;
END;
$$;

COMMENT ON FUNCTION dataload_simulation.get_state_province_id IS 'Returns the state province ID for a given code';
