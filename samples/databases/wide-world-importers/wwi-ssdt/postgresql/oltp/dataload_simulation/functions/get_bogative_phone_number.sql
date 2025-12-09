-- PostgreSQL equivalent of [DataLoadSimulation].GetBogativePhoneNumber
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE FUNCTION dataload_simulation.get_bogative_phone_number(
    p_area_code VARCHAR(4)
)
RETURNS VARCHAR(20)
LANGUAGE plpgsql
VOLATILE
AS $$
DECLARE
    v_phone_number VARCHAR(20);
    v_exchange VARCHAR(3);
    v_subscriber VARCHAR(4);
BEGIN
    -- Generate a bogus phone number with format (XXX) 555-XXXX
    -- Using 555 exchange which is reserved for fictional use
    v_exchange := '555';
    v_subscriber := LPAD((FLOOR(RANDOM() * 10000))::TEXT, 4, '0');
    
    v_phone_number := '(' || p_area_code || ') ' || v_exchange || '-' || v_subscriber;
    
    RETURN v_phone_number;
END;
$$;

COMMENT ON FUNCTION dataload_simulation.get_bogative_phone_number IS 'Generates a fictional phone number for data simulation';
