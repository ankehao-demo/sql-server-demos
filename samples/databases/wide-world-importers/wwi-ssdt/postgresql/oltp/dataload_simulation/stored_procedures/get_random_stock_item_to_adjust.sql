-- PostgreSQL equivalent of [DataLoadSimulation].GetRandomStockItemToAdjust
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE PROCEDURE dataload_simulation.get_random_stock_item_to_adjust(
    INOUT p_random_stock_item_id INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
    SELECT stock_item_id INTO p_random_stock_item_id
    FROM warehouse.stock_items
    WHERE valid_to = '9999-12-31 23:59:59.999999'::TIMESTAMP
    ORDER BY RANDOM()
    LIMIT 1;
END;
$$;

COMMENT ON PROCEDURE dataload_simulation.get_random_stock_item_to_adjust IS 'Selects a random stock item ID for adjustment';
