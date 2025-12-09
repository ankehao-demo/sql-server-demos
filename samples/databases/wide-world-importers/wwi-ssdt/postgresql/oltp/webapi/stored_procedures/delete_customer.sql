-- PostgreSQL equivalent of [WebApi].DeleteCustomer
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE PROCEDURE webapi.delete_customer(
    p_customer_id INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    DELETE FROM sales.customers
    WHERE customer_id = p_customer_id;
END;
$$;

COMMENT ON PROCEDURE webapi.delete_customer IS 'Deletes a customer by ID';
