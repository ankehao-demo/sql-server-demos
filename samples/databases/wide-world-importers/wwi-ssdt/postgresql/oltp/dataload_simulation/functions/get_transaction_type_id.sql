-- PostgreSQL equivalent of [DataLoadSimulation].GetTransactionTypeID
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE FUNCTION dataload_simulation.get_transaction_type_id(
    p_transaction_type_name VARCHAR(50)
)
RETURNS INTEGER
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    v_transaction_type_id INTEGER;
BEGIN
    SELECT transaction_type_id INTO v_transaction_type_id
    FROM application.transaction_types
    WHERE transaction_type_name = p_transaction_type_name
    AND valid_to = '9999-12-31 23:59:59.999999'::TIMESTAMP
    LIMIT 1;
    
    RETURN v_transaction_type_id;
END;
$$;

COMMENT ON FUNCTION dataload_simulation.get_transaction_type_id IS 'Returns the transaction type ID for a given name';
