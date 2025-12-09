-- PostgreSQL equivalent of [DataLoadSimulation].GetRandomCustomerCategory
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE PROCEDURE dataload_simulation.get_random_customer_category(
    INOUT p_random_customer_category_id INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
    SELECT customer_category_id INTO p_random_customer_category_id
    FROM sales.customer_categories
    WHERE valid_to = '9999-12-31 23:59:59.999999'::TIMESTAMP
    ORDER BY RANDOM()
    LIMIT 1;
END;
$$;

COMMENT ON PROCEDURE dataload_simulation.get_random_customer_category IS 'Selects a random customer category ID';
