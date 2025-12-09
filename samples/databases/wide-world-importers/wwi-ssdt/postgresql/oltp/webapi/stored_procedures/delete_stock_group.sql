-- PostgreSQL equivalent of [WebApi].DeleteStockGroup
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE PROCEDURE webapi.delete_stock_group(
    p_stock_group_id INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    DELETE FROM warehouse.stock_groups
    WHERE stock_group_id = p_stock_group_id;
END;
$$;

COMMENT ON PROCEDURE webapi.delete_stock_group IS 'Deletes a stock group by ID';
