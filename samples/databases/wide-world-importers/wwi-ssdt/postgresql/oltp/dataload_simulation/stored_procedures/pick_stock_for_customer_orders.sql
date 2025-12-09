-- PostgreSQL equivalent of [DataLoadSimulation].PickStockForCustomerOrders
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE PROCEDURE dataload_simulation.pick_stock_for_customer_orders(
    p_current_date_time TIMESTAMP,
    p_starting_when TIMESTAMP,
    p_end_of_time TIMESTAMP,
    p_is_silent_mode BOOLEAN
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_picker_person_id INTEGER;
    v_order_id INTEGER;
    v_order_line_id INTEGER;
    v_stock_item_id INTEGER;
    v_quantity INTEGER;
    v_quantity_on_hand INTEGER;
    v_picked_quantity INTEGER;
    order_cursor CURSOR FOR
        SELECT o.order_id
        FROM sales.orders o
        WHERE o.picking_completed_when IS NULL
        AND o.order_date <= p_current_date_time::DATE
        ORDER BY o.order_id;
    order_line_cursor CURSOR (p_order_id INTEGER) FOR
        SELECT ol.order_line_id, ol.stock_item_id, ol.quantity
        FROM sales.order_lines ol
        WHERE ol.order_id = p_order_id
        AND ol.picked_quantity < ol.quantity;
BEGIN
    -- Get a random picker
    SELECT person_id INTO v_picker_person_id
    FROM application.people
    WHERE is_employee = true
    ORDER BY RANDOM()
    LIMIT 1;
    
    -- Process each order
    OPEN order_cursor;
    
    LOOP
        FETCH order_cursor INTO v_order_id;
        EXIT WHEN NOT FOUND;
        
        -- Process each order line
        OPEN order_line_cursor(v_order_id);
        
        LOOP
            FETCH order_line_cursor INTO v_order_line_id, v_stock_item_id, v_quantity;
            EXIT WHEN NOT FOUND;
            
            -- Get current stock on hand
            SELECT quantity_on_hand INTO v_quantity_on_hand
            FROM warehouse.stock_item_holdings
            WHERE stock_item_id = v_stock_item_id;
            
            -- Calculate how much we can pick
            v_picked_quantity := LEAST(v_quantity, COALESCE(v_quantity_on_hand, 0));
            
            IF v_picked_quantity > 0 THEN
                -- Update order line with picked quantity
                UPDATE sales.order_lines
                SET picked_quantity = v_picked_quantity,
                    picking_completed_when = CASE 
                        WHEN v_picked_quantity >= v_quantity THEN p_starting_when 
                        ELSE NULL 
                    END,
                    last_edited_by = v_picker_person_id,
                    last_edited_when = p_starting_when
                WHERE order_line_id = v_order_line_id;
            END IF;
        END LOOP;
        
        CLOSE order_line_cursor;
        
        -- Check if all lines are picked for this order
        IF NOT EXISTS (
            SELECT 1 FROM sales.order_lines
            WHERE order_id = v_order_id
            AND picked_quantity < quantity
        ) THEN
            -- Mark order as fully picked
            UPDATE sales.orders
            SET picking_completed_when = p_starting_when,
                picked_by_person_id = v_picker_person_id,
                last_edited_by = v_picker_person_id,
                last_edited_when = p_starting_when
            WHERE order_id = v_order_id;
        END IF;
    END LOOP;
    
    CLOSE order_cursor;
END;
$$;

COMMENT ON PROCEDURE dataload_simulation.pick_stock_for_customer_orders IS 'Picks stock for customer orders during data simulation';
