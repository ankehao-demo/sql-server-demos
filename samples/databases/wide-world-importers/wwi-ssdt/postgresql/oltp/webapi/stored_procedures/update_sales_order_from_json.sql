-- PostgreSQL equivalent of [WebApi].UpdateSalesOrderFromJson
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE PROCEDURE webapi.update_sales_order_from_json(
    p_sales_order JSONB,
    p_order_id INTEGER,
    p_user_id INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE sales.orders SET
        customer_id = COALESCE((p_sales_order->>'CustomerID')::INTEGER, customer_id),
        salesperson_person_id = COALESCE((p_sales_order->>'SalespersonPersonID')::INTEGER, salesperson_person_id),
        picked_by_person_id = (p_sales_order->>'PickedByPersonID')::INTEGER,
        contact_person_id = COALESCE((p_sales_order->>'ContactPersonID')::INTEGER, contact_person_id),
        backorder_order_id = (p_sales_order->>'BackorderOrderID')::INTEGER,
        order_date = COALESCE((p_sales_order->>'OrderDate')::DATE, order_date),
        expected_delivery_date = COALESCE((p_sales_order->>'ExpectedDeliveryDate')::DATE, expected_delivery_date),
        customer_purchase_order_number = (p_sales_order->>'CustomerPurchaseOrderNumber')::VARCHAR(20),
        is_undersupply_backordered = COALESCE((p_sales_order->>'IsUndersupplyBackordered')::BOOLEAN, is_undersupply_backordered),
        comments = (p_sales_order->>'Comments')::TEXT,
        delivery_instructions = (p_sales_order->>'DeliveryInstructions')::TEXT,
        internal_comments = (p_sales_order->>'InternalComments')::TEXT,
        picking_completed_when = (p_sales_order->>'PickingCompletedWhen')::TIMESTAMP,
        last_edited_by = p_user_id
    WHERE order_id = p_order_id;
END;
$$;

COMMENT ON PROCEDURE webapi.update_sales_order_from_json IS 'Updates a sales order from JSON';
