-- PostgreSQL equivalent of [WebApi].InsertStockGroupsFromJson
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE FUNCTION webapi.insert_stock_groups_from_json(
    p_stock_groups JSONB,
    p_user_id INTEGER
)
RETURNS TABLE (stock_group_id INTEGER)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    INSERT INTO warehouse.stock_groups(stock_group_name, last_edited_by)
    SELECT 
        (item->>'StockGroupName')::VARCHAR(50),
        p_user_id
    FROM jsonb_array_elements(p_stock_groups) AS item
    RETURNING warehouse.stock_groups.stock_group_id;
END;
$$;

COMMENT ON FUNCTION webapi.insert_stock_groups_from_json IS 'Inserts stock groups from JSON array and returns inserted IDs';
