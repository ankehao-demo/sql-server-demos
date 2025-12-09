-- PostgreSQL equivalent of [DataLoadSimulation].GetRandomSalesPersonID
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE PROCEDURE dataload_simulation.get_random_sales_person_id(
    INOUT p_random_sales_person_id INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
    SELECT person_id INTO p_random_sales_person_id
    FROM application.people
    WHERE is_salesperson = true
    AND valid_to = '9999-12-31 23:59:59.999999'::TIMESTAMP
    ORDER BY RANDOM()
    LIMIT 1;
END;
$$;

COMMENT ON PROCEDURE dataload_simulation.get_random_sales_person_id IS 'Selects a random salesperson ID';
