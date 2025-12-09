-- PostgreSQL equivalent of [Integration].GetPurchaseUpdates
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE FUNCTION integration.get_purchase_updates(
    p_last_cutoff TIMESTAMP,
    p_new_cutoff TIMESTAMP
)
RETURNS TABLE (
    wwi_purchase_order_id INTEGER,
    wwi_supplier_id INTEGER,
    wwi_stock_item_id INTEGER,
    ordered_outers INTEGER,
    ordered_quantity INTEGER,
    received_outers INTEGER,
    package VARCHAR(50),
    is_order_finalized BOOLEAN,
    order_date DATE,
    expected_delivery_date DATE,
    last_receipt_date DATE,
    last_modified_when TIMESTAMP
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT po.purchase_order_id,
           po.supplier_id,
           pol.stock_item_id,
           pol.ordered_outers,
           pol.ordered_outers * si.quantity_per_outer,
           pol.received_outers,
           pt.package_type_name,
           po.is_order_finalized,
           po.order_date,
           po.expected_delivery_date,
           pol.last_receipt_date,
           pol.last_edited_when
    FROM purchasing.purchase_orders po
    JOIN purchasing.purchase_order_lines pol ON po.purchase_order_id = pol.purchase_order_id
    JOIN warehouse.stock_items si ON pol.stock_item_id = si.stock_item_id
    LEFT JOIN warehouse.package_types pt ON pol.package_type_id = pt.package_type_id
    WHERE pol.last_edited_when > p_last_cutoff
    AND pol.last_edited_when <= p_new_cutoff
    ORDER BY po.purchase_order_id, pol.purchase_order_line_id;
END;
$$;

COMMENT ON FUNCTION integration.get_purchase_updates IS 'Returns purchase fact updates for ETL processing';
