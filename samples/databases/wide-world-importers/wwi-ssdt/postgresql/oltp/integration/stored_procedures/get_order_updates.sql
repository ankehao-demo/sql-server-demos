-- PostgreSQL equivalent of [Integration].GetOrderUpdates
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE FUNCTION integration.get_order_updates(
    p_last_cutoff TIMESTAMP,
    p_new_cutoff TIMESTAMP
)
RETURNS TABLE (
    wwi_order_id INTEGER,
    wwi_customer_id INTEGER,
    wwi_salesperson_id INTEGER,
    wwi_picker_id INTEGER,
    wwi_backorder_order_id INTEGER,
    description VARCHAR(100),
    package VARCHAR(50),
    quantity INTEGER,
    unit_price DECIMAL(18,2),
    tax_rate DECIMAL(18,3),
    total_excluding_tax DECIMAL(18,2),
    tax_amount DECIMAL(18,2),
    total_including_tax DECIMAL(18,2),
    order_date DATE,
    expected_delivery_date DATE,
    picked_date DATE,
    last_modified_when TIMESTAMP
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT o.order_id,
           o.customer_id,
           o.salesperson_person_id,
           o.picked_by_person_id,
           o.backorder_order_id,
           ol.description,
           pt.package_type_name,
           ol.quantity,
           ol.unit_price,
           ol.tax_rate,
           ROUND(ol.quantity * ol.unit_price, 2)::DECIMAL(18,2),
           ROUND(ol.quantity * ol.unit_price * ol.tax_rate / 100.0, 2)::DECIMAL(18,2),
           ROUND(ol.quantity * ol.unit_price * (1 + ol.tax_rate / 100.0), 2)::DECIMAL(18,2),
           o.order_date,
           o.expected_delivery_date,
           o.picking_completed_when::DATE,
           ol.last_edited_when
    FROM sales.orders o
    JOIN sales.order_lines ol ON o.order_id = ol.order_id
    LEFT JOIN warehouse.package_types pt ON ol.package_type_id = pt.package_type_id
    WHERE ol.last_edited_when > p_last_cutoff
    AND ol.last_edited_when <= p_new_cutoff
    ORDER BY o.order_id, ol.order_line_id;
END;
$$;

COMMENT ON FUNCTION integration.get_order_updates IS 'Returns order fact updates for ETL processing';
