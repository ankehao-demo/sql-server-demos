-- PostgreSQL equivalent of [Website].SearchForStockItems
-- Converted from T-SQL to PL/pgSQL
-- Returns JSON result like SQL Server's FOR JSON AUTO

CREATE OR REPLACE FUNCTION website.search_for_stock_items(
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
        WHERE si.search_details ILIKE '%' || p_search_text || '%'
        ORDER BY si.stock_item_name
        LIMIT p_maximum_rows_to_return
    ) si;
    
    RETURN v_result;
END;
$$;

COMMENT ON FUNCTION website.search_for_stock_items IS 'Searches for stock items by search details and returns JSON result';
