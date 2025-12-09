-- PostgreSQL equivalent of [DataLoadSimulation].GetRandomBuyingGroupNotInUse
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE PROCEDURE dataload_simulation.get_random_buying_group_not_in_use(
    INOUT p_random_buying_group_id INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Get a buying group that is not currently assigned to any customer
    SELECT bg.buying_group_id INTO p_random_buying_group_id
    FROM sales.buying_groups bg
    WHERE bg.valid_to = '9999-12-31 23:59:59.999999'::TIMESTAMP
    AND NOT EXISTS (
        SELECT 1 FROM sales.customers c
        WHERE c.buying_group_id = bg.buying_group_id
        AND c.valid_to = '9999-12-31 23:59:59.999999'::TIMESTAMP
    )
    ORDER BY RANDOM()
    LIMIT 1;
    
    -- If all buying groups are in use, just get a random one
    IF p_random_buying_group_id IS NULL THEN
        SELECT buying_group_id INTO p_random_buying_group_id
        FROM sales.buying_groups
        WHERE valid_to = '9999-12-31 23:59:59.999999'::TIMESTAMP
        ORDER BY RANDOM()
        LIMIT 1;
    END IF;
END;
$$;

COMMENT ON PROCEDURE dataload_simulation.get_random_buying_group_not_in_use IS 'Selects a random buying group ID that is not currently in use';
