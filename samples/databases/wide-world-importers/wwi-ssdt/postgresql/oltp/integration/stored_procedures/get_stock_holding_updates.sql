-- PostgreSQL equivalent of [Integration].GetStockHoldingUpdates
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE FUNCTION integration.get_stock_holding_updates(
    p_last_cutoff TIMESTAMP,
    p_new_cutoff TIMESTAMP
)
RETURNS TABLE (
    wwi_stock_item_id INTEGER,
    quantity_on_hand INTEGER,
    bin_location VARCHAR(20),
    last_stocktake_quantity INTEGER,
    last_cost_price DECIMAL(18,2),
    reorder_level INTEGER,
    target_stock_level INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT sih.stock_item_id,
           sih.quantity_on_hand,
           sih.bin_location,
           sih.last_stocktake_quantity,
           sih.last_cost_price,
           sih.reorder_level,
           sih.target_stock_level
    FROM warehouse.stock_item_holdings sih
    WHERE sih.last_edited_when > p_last_cutoff
    AND sih.last_edited_when <= p_new_cutoff
    ORDER BY sih.stock_item_id;
END;
$$;

COMMENT ON FUNCTION integration.get_stock_holding_updates IS 'Returns stock holding updates for ETL processing';
