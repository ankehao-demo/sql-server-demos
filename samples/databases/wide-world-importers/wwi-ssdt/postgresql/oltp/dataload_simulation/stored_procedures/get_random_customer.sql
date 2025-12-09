-- PostgreSQL equivalent of [DataLoadSimulation].GetRandomCustomer
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE PROCEDURE dataload_simulation.get_random_customer(
    INOUT p_random_customer_id INTEGER,
    INOUT p_customer_primary_contact_person_id INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
    SELECT c.customer_id, c.primary_contact_person_id
    INTO p_random_customer_id, p_customer_primary_contact_person_id
    FROM sales.customers c
    WHERE c.is_on_credit_hold = false
    AND c.valid_to = '9999-12-31 23:59:59.999999'::TIMESTAMP
    ORDER BY RANDOM()
    LIMIT 1;
END;
$$;

COMMENT ON PROCEDURE dataload_simulation.get_random_customer IS 'Selects a random customer ID and their primary contact person ID';
