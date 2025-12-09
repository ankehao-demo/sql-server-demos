-- PostgreSQL equivalent of [WebApi].UpdateStockGroupFromJson
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE PROCEDURE webapi.update_stock_group_from_json(
    p_stock_group JSONB,
    p_stock_group_id INTEGER,
    p_user_id INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE warehouse.stock_groups SET
        stock_group_name = (p_stock_group->>'StockGroupName')::VARCHAR(50),
        last_edited_by = p_user_id
    WHERE stock_group_id = p_stock_group_id;
END;
$$;

COMMENT ON PROCEDURE webapi.update_stock_group_from_json IS 'Updates a stock group from JSON';
