-- PostgreSQL equivalent of [Website].SearchForStockItemsByTags
-- Converted from T-SQL to PL/pgSQL
-- Returns JSON result like SQL Server's FOR JSON AUTO

CREATE OR REPLACE FUNCTION website.search_for_stock_items_by_tags(
    p_search_text VARCHAR(1000),
    p_maximum_rows_to_return INTEGER
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_result JSON;
BEGIN
    SELECT json_build_object(
        'StockItems',
        COALESCE(json_agg(
            json_build_object(
                'StockItemID', si.stock_item_id,
                'StockItemName', si.stock_item_name
            )
        ), '[]'::json)
    ) INTO v_result
    FROM (
        SELECT si.stock_item_id, si.stock_item_name
        FROM warehouse.stock_items si
        WHERE si.tags::text ILIKE '%' || p_search_text || '%'
        ORDER BY si.stock_item_name
        LIMIT p_maximum_rows_to_return
    ) si;
    
    RETURN v_result;
END;
$$;

COMMENT ON FUNCTION website.search_for_stock_items_by_tags IS 'Searches for stock items by tags and returns JSON result';
