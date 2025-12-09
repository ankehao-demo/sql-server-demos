-- PostgreSQL equivalent of [Integration].GetMovementUpdates
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE FUNCTION integration.get_movement_updates(
    p_last_cutoff TIMESTAMP,
    p_new_cutoff TIMESTAMP
)
RETURNS TABLE (
    wwi_stock_item_transaction_id INTEGER,
    wwi_stock_item_id INTEGER,
    wwi_customer_id INTEGER,
    wwi_supplier_id INTEGER,
    wwi_transaction_type_id INTEGER,
    wwi_invoice_id INTEGER,
    wwi_purchase_order_id INTEGER,
    quantity INTEGER,
    transaction_occurred_when TIMESTAMP
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT sit.stock_item_transaction_id,
           sit.stock_item_id,
           sit.customer_id,
           sit.supplier_id,
           sit.transaction_type_id,
           sit.invoice_id,
           sit.purchase_order_id,
           sit.quantity,
           sit.transaction_occurred_when
    FROM warehouse.stock_item_transactions sit
    WHERE sit.last_edited_when > p_last_cutoff
    AND sit.last_edited_when <= p_new_cutoff
    ORDER BY sit.stock_item_transaction_id;
END;
$$;

COMMENT ON FUNCTION integration.get_movement_updates IS 'Returns stock movement fact updates for ETL processing';
