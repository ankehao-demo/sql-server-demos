-- PostgreSQL equivalent of [WebApi].DeleteBuyingGroup
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE PROCEDURE webapi.delete_buying_group(
    p_buying_group_id INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    DELETE FROM sales.buying_groups
    WHERE buying_group_id = p_buying_group_id;
END;
$$;

COMMENT ON PROCEDURE webapi.delete_buying_group IS 'Deletes a buying group by ID';
