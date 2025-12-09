-- PostgreSQL equivalent of [DataLoadSimulation].GetRandomBuyingGroup
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE PROCEDURE dataload_simulation.get_random_buying_group(
    INOUT p_random_buying_group_id INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
    SELECT buying_group_id INTO p_random_buying_group_id
    FROM sales.buying_groups
    WHERE valid_to = '9999-12-31 23:59:59.999999'::TIMESTAMP
    ORDER BY RANDOM()
    LIMIT 1;
END;
$$;

COMMENT ON PROCEDURE dataload_simulation.get_random_buying_group IS 'Selects a random buying group ID';
