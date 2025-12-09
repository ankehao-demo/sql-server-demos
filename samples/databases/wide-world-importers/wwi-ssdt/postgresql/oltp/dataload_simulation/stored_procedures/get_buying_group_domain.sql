-- PostgreSQL equivalent of [DataLoadSimulation].GetBuyingGroupDomain
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE PROCEDURE dataload_simulation.get_buying_group_domain(
    p_buying_group_id INTEGER,
    INOUT p_domain VARCHAR(256)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_buying_group_name VARCHAR(50);
BEGIN
    -- Get the buying group name
    SELECT buying_group_name INTO v_buying_group_name
    FROM sales.buying_groups
    WHERE buying_group_id = p_buying_group_id
    AND valid_to = '9999-12-31 23:59:59.999999'::TIMESTAMP;
    
    IF v_buying_group_name IS NOT NULL THEN
        -- Convert to domain format (lowercase, remove spaces, add .com)
        p_domain := LOWER(REPLACE(v_buying_group_name, ' ', '')) || '.com';
    ELSE
        p_domain := 'example.com';
    END IF;
END;
$$;

COMMENT ON PROCEDURE dataload_simulation.get_buying_group_domain IS 'Gets the domain name for a buying group';
