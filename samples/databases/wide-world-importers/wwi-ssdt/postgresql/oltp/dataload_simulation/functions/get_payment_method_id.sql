-- PostgreSQL equivalent of [DataLoadSimulation].GetPaymentMethodID
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE FUNCTION dataload_simulation.get_payment_method_id(
    p_payment_method_name VARCHAR(50)
)
RETURNS INTEGER
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    v_payment_method_id INTEGER;
BEGIN
    SELECT payment_method_id INTO v_payment_method_id
    FROM application.payment_methods
    WHERE payment_method_name = p_payment_method_name
    AND valid_to = '9999-12-31 23:59:59.999999'::TIMESTAMP
    LIMIT 1;
    
    RETURN v_payment_method_id;
END;
$$;

COMMENT ON FUNCTION dataload_simulation.get_payment_method_id IS 'Returns the payment method ID for a given name';
