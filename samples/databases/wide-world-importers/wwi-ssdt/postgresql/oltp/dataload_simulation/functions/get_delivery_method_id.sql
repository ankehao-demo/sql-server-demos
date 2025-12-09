-- PostgreSQL equivalent of [DataLoadSimulation].GetDeliveryMethodID
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE FUNCTION dataload_simulation.get_delivery_method_id(
    p_delivery_method_name VARCHAR(50)
)
RETURNS INTEGER
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    v_delivery_method_id INTEGER;
BEGIN
    SELECT delivery_method_id INTO v_delivery_method_id
    FROM application.delivery_methods
    WHERE delivery_method_name = p_delivery_method_name
    AND valid_to = '9999-12-31 23:59:59.999999'::TIMESTAMP
    LIMIT 1;
    
    RETURN v_delivery_method_id;
END;
$$;

COMMENT ON FUNCTION dataload_simulation.get_delivery_method_id IS 'Returns the delivery method ID for a given name';
