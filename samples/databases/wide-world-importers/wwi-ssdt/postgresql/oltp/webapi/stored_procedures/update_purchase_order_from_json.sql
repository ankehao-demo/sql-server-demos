-- PostgreSQL equivalent of [WebApi].UpdatePurchaseOrderFromJson
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE PROCEDURE webapi.update_purchase_order_from_json(
    p_purchase_order JSONB,
    p_purchase_order_id INTEGER,
    p_user_id INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE purchasing.purchase_orders SET
        supplier_id = COALESCE((p_purchase_order->>'SupplierID')::INTEGER, supplier_id),
        delivery_method_id = COALESCE((p_purchase_order->>'DeliveryMethodID')::INTEGER, delivery_method_id),
        contact_person_id = COALESCE((p_purchase_order->>'ContactPersonID')::INTEGER, contact_person_id),
        order_date = COALESCE((p_purchase_order->>'OrderDate')::DATE, order_date),
        expected_delivery_date = COALESCE((p_purchase_order->>'ExpectedDeliveryDate')::DATE, expected_delivery_date),
        supplier_reference = (p_purchase_order->>'SupplierReference')::VARCHAR(20),
        is_order_finalized = COALESCE((p_purchase_order->>'IsOrderFinalized')::BOOLEAN, is_order_finalized),
        comments = (p_purchase_order->>'Comments')::TEXT,
        internal_comments = (p_purchase_order->>'InternalComments')::TEXT,
        last_edited_by = p_user_id
    WHERE purchase_order_id = p_purchase_order_id;
END;
$$;

COMMENT ON PROCEDURE webapi.update_purchase_order_from_json IS 'Updates a purchase order from JSON';
