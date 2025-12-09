-- PostgreSQL equivalent of [DataLoadSimulation].PlaceSupplierOrders
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE PROCEDURE dataload_simulation.place_supplier_orders(
    p_current_date_time TIMESTAMP,
    p_starting_when TIMESTAMP,
    p_end_of_time TIMESTAMP,
    p_is_silent_mode BOOLEAN
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_staff_member_person_id INTEGER;
    v_purchase_order_id INTEGER;
    v_stock_item_id INTEGER;
    v_supplier_id INTEGER;
    v_quantity_on_hand INTEGER;
    v_reorder_level INTEGER;
    v_target_stock_level INTEGER;
    v_quantity_per_outer INTEGER;
    v_typical_weight_per_unit DECIMAL(18,3);
    v_unit_price DECIMAL(18,2);
    v_order_quantity INTEGER;
    v_expected_delivery_date DATE;
BEGIN
    -- Get a random staff member
    SELECT person_id INTO v_staff_member_person_id
    FROM application.people
    WHERE is_employee = true
    ORDER BY RANDOM()
    LIMIT 1;
    
    -- Calculate expected delivery date (3-7 days from now, excluding weekends)
    v_expected_delivery_date := (p_current_date_time + INTERVAL '3 days')::DATE;
    WHILE EXTRACT(DOW FROM v_expected_delivery_date) IN (0, 6) LOOP
        v_expected_delivery_date := v_expected_delivery_date + INTERVAL '1 day';
    END LOOP;
    
    -- Find stock items that need reordering
    FOR v_stock_item_id, v_supplier_id, v_quantity_on_hand, v_reorder_level, 
        v_target_stock_level, v_quantity_per_outer, v_typical_weight_per_unit, v_unit_price IN
        SELECT si.stock_item_id, si.supplier_id, sih.quantity_on_hand, sih.reorder_level,
               sih.target_stock_level, si.quantity_per_outer, si.typical_weight_per_unit, si.unit_price
        FROM warehouse.stock_items si
        JOIN warehouse.stock_item_holdings sih ON si.stock_item_id = sih.stock_item_id
        WHERE sih.quantity_on_hand < sih.reorder_level
        AND NOT EXISTS (
            SELECT 1 FROM purchasing.purchase_order_lines pol
            JOIN purchasing.purchase_orders po ON pol.purchase_order_id = po.purchase_order_id
            WHERE pol.stock_item_id = si.stock_item_id
            AND po.is_order_finalized = false
        )
    LOOP
        -- Calculate order quantity to reach target stock level
        v_order_quantity := CEIL((v_target_stock_level - v_quantity_on_hand)::FLOAT / v_quantity_per_outer)::INTEGER;
        
        IF v_order_quantity > 0 THEN
            -- Get next purchase order ID
            v_purchase_order_id := nextval('sequences.purchase_order_id');
            
            -- Create purchase order
            INSERT INTO purchasing.purchase_orders (
                purchase_order_id, supplier_id, order_date, delivery_method_id,
                contact_person_id, expected_delivery_date, supplier_reference,
                is_order_finalized, comments, internal_comments,
                last_edited_by, last_edited_when
            )
            SELECT v_purchase_order_id, v_supplier_id, p_current_date_time::DATE,
                   s.delivery_method_id, s.primary_contact_person_id, v_expected_delivery_date,
                   'PO-' || v_purchase_order_id::TEXT, false, NULL, NULL,
                   v_staff_member_person_id, p_starting_when
            FROM purchasing.suppliers s
            WHERE s.supplier_id = v_supplier_id;
            
            -- Create purchase order line
            INSERT INTO purchasing.purchase_order_lines (
                purchase_order_id, stock_item_id, ordered_outers, description,
                received_outers, package_type_id, expected_unit_price_per_outer,
                last_receipt_date, is_order_line_finalized, last_edited_by, last_edited_when
            )
            SELECT v_purchase_order_id, v_stock_item_id, v_order_quantity,
                   si.stock_item_name, 0, si.outer_package_id,
                   si.unit_price * si.quantity_per_outer,
                   NULL, false, v_staff_member_person_id, p_starting_when
            FROM warehouse.stock_items si
            WHERE si.stock_item_id = v_stock_item_id;
        END IF;
    END LOOP;
END;
$$;

COMMENT ON PROCEDURE dataload_simulation.place_supplier_orders IS 'Simulates placing supplier orders for low stock items';
