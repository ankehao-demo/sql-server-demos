-- PostgreSQL equivalent of [WebApi].DeleteStockItem
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE PROCEDURE webapi.delete_stock_item(
    p_stock_item_id INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    DELETE FROM warehouse.stock_items
    WHERE stock_item_id = p_stock_item_id;
END;
$$;

COMMENT ON PROCEDURE webapi.delete_stock_item IS 'Deletes a stock item by ID';
