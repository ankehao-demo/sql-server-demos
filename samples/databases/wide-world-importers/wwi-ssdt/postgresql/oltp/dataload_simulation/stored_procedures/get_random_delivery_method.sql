-- PostgreSQL equivalent of [DataLoadSimulation].GetRandomDeliveryMethod
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE PROCEDURE dataload_simulation.get_random_delivery_method(
    INOUT p_random_delivery_method_id INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
    SELECT delivery_method_id INTO p_random_delivery_method_id
    FROM application.delivery_methods
    WHERE valid_to = '9999-12-31 23:59:59.999999'::TIMESTAMP
    ORDER BY RANDOM()
    LIMIT 1;
END;
$$;

COMMENT ON PROCEDURE dataload_simulation.get_random_delivery_method IS 'Selects a random delivery method ID';
