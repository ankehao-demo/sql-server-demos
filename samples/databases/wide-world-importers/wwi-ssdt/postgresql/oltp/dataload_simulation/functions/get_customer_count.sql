-- PostgreSQL equivalent of [DataLoadSimulation].GetCustomerCount
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE FUNCTION dataload_simulation.get_customer_count()
RETURNS INTEGER
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    v_customer_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_customer_count
    FROM sales.customers
    WHERE valid_to = '9999-12-31 23:59:59.999999'::TIMESTAMP;
    
    RETURN v_customer_count;
END;
$$;

COMMENT ON FUNCTION dataload_simulation.get_customer_count IS 'Returns the count of active customers';
