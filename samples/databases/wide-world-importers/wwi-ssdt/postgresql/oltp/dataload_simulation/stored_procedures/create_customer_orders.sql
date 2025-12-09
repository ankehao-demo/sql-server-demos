-- PostgreSQL equivalent of [DataLoadSimulation].CreateCustomerOrders
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE PROCEDURE dataload_simulation.create_customer_orders(
    p_current_date_time TIMESTAMP,
    p_starting_when TIMESTAMP,
    p_end_of_time TIMESTAMP,
    p_number_of_customer_orders INTEGER,
    p_is_silent_mode BOOLEAN
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_order_counter INTEGER := 0;
    v_order_line_counter INTEGER;
    v_customer_id INTEGER;
    v_order_id INTEGER;
    v_primary_contact_person_id INTEGER;
    v_salesperson_person_id INTEGER;
    v_expected_delivery_date DATE;
    v_order_date_time TIMESTAMP;
    v_number_of_order_lines INTEGER;
    v_stock_item_id INTEGER;
    v_stock_item_name VARCHAR(100);
    v_unit_package_id INTEGER;
    v_quantity_per_outer INTEGER;
    v_quantity INTEGER;
    v_customer_price DECIMAL(18,2);
    v_tax_rate DECIMAL(18,3);
BEGIN
    v_expected_delivery_date := (p_current_date_time + INTERVAL '1 day')::DATE;
    v_order_date_time := p_starting_when;
    
    -- No deliveries on weekends (Sunday = 0, Saturday = 6 in PostgreSQL)
    WHILE EXTRACT(DOW FROM v_expected_delivery_date) IN (0, 6) LOOP
        v_expected_delivery_date := v_expected_delivery_date + INTERVAL '1 day';
    END LOOP;
    
    -- Generate the required orders
    WHILE v_order_counter < p_number_of_customer_orders LOOP
        -- Get next order ID from sequence
        v_order_id := nextval('sequences.order_id');
        
        -- Get random customer
        CALL dataload_simulation.get_random_customer(v_customer_id, v_primary_contact_person_id);
        
        -- Get random salesperson
        CALL dataload_simulation.get_random_sales_person_id(v_salesperson_person_id);
        
        -- Insert order
        INSERT INTO sales.orders (
            order_id, customer_id, salesperson_person_id, picked_by_person_id, 
            contact_person_id, backorder_order_id, order_date,
            expected_delivery_date, customer_purchase_order_number, 
            is_undersupply_backordered, comments, delivery_instructions, 
            internal_comments, picking_completed_when, last_edited_by, last_edited_when
        )
        VALUES (
            v_order_id, v_customer_id, v_salesperson_person_id, NULL,
            v_primary_contact_person_id, NULL, p_current_date_time::DATE,
            v_expected_delivery_date, (CEIL(RANDOM() * 10000) + 10000)::TEXT,
            true, NULL, NULL,
            NULL, NULL, 1, v_order_date_time
        );
        
        -- Generate 1-5 order lines
        v_number_of_order_lines := 1 + CEIL(RANDOM() * 4)::INTEGER;
        v_order_line_counter := 0;
        
        WHILE v_order_line_counter < v_number_of_order_lines LOOP
            -- Get random stock item not already in this order
            SELECT si.stock_item_id, si.stock_item_name, si.unit_package_id,
                   si.quantity_per_outer, si.tax_rate
            INTO v_stock_item_id, v_stock_item_name, v_unit_package_id,
                 v_quantity_per_outer, v_tax_rate
            FROM warehouse.stock_items si
            WHERE NOT EXISTS (
                SELECT 1 FROM sales.order_lines ol
                WHERE ol.order_id = v_order_id
                AND ol.stock_item_id = si.stock_item_id
            )
            ORDER BY RANDOM()
            LIMIT 1;
            
            IF v_stock_item_id IS NOT NULL THEN
                v_quantity := v_quantity_per_outer * (1 + FLOOR(RANDOM() * 10)::INTEGER);
                v_customer_price := website.calculate_customer_price(v_customer_id, v_stock_item_id, p_current_date_time);
                
                INSERT INTO sales.order_lines (
                    order_id, stock_item_id, description, package_type_id, quantity, 
                    unit_price, tax_rate, picked_quantity, picking_completed_when, 
                    last_edited_by, last_edited_when
                )
                VALUES (
                    v_order_id, v_stock_item_id, v_stock_item_name, v_unit_package_id, 
                    v_quantity, v_customer_price, v_tax_rate, 0, NULL, 
                    1, p_starting_when
                );
            END IF;
            
            v_order_line_counter := v_order_line_counter + 1;
        END LOOP;
        
        v_order_counter := v_order_counter + 1;
    END LOOP;
END;
$$;

COMMENT ON PROCEDURE dataload_simulation.create_customer_orders IS 'Creates simulated customer orders for data generation';
