-- PostgreSQL equivalent of [DataLoadSimulation].AddStockItems
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE PROCEDURE dataload_simulation.add_stock_items(
    p_current_date_time TIMESTAMP,
    p_starting_when TIMESTAMP,
    p_end_of_time TIMESTAMP,
    p_is_silent_mode BOOLEAN
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_staff_member_person_id INTEGER;
    v_stock_item_id INTEGER;
    v_stock_item_name VARCHAR(100);
    v_supplier_id INTEGER;
    v_color_id INTEGER;
    v_unit_package_id INTEGER;
    v_outer_package_id INTEGER;
    v_brand VARCHAR(50);
    v_size VARCHAR(20);
    v_lead_time_days INTEGER;
    v_quantity_per_outer INTEGER;
    v_is_chiller_stock BOOLEAN;
    v_barcode VARCHAR(50);
    v_tax_rate DECIMAL(18,3);
    v_unit_price DECIMAL(18,2);
    v_recommended_retail_price DECIMAL(18,2);
    v_typical_weight_per_unit DECIMAL(18,3);
    v_num_new_items INTEGER;
    v_counter INTEGER := 0;
BEGIN
    -- Get a random staff member
    SELECT person_id INTO v_staff_member_person_id
    FROM application.people
    WHERE is_employee = true
    ORDER BY RANDOM()
    LIMIT 1;
    
    -- Randomly add 0-1 new stock items (rare event)
    v_num_new_items := CASE WHEN RANDOM() < 0.1 THEN 1 ELSE 0 END;
    
    WHILE v_counter < v_num_new_items LOOP
        -- Get next stock item ID
        v_stock_item_id := nextval('sequences.stock_item_id');
        
        -- Generate stock item data
        v_stock_item_name := 'New Product ' || v_stock_item_id::TEXT;
        
        -- Get random supplier
        SELECT supplier_id INTO v_supplier_id
        FROM purchasing.suppliers
        WHERE valid_to = '9999-12-31 23:59:59.999999'::TIMESTAMP
        ORDER BY RANDOM()
        LIMIT 1;
        
        -- Get random color
        SELECT color_id INTO v_color_id
        FROM warehouse.colors
        WHERE valid_to = '9999-12-31 23:59:59.999999'::TIMESTAMP
        ORDER BY RANDOM()
        LIMIT 1;
        
        -- Get random package types
        SELECT package_type_id INTO v_unit_package_id
        FROM warehouse.package_types
        WHERE valid_to = '9999-12-31 23:59:59.999999'::TIMESTAMP
        ORDER BY RANDOM()
        LIMIT 1;
        
        SELECT package_type_id INTO v_outer_package_id
        FROM warehouse.package_types
        WHERE valid_to = '9999-12-31 23:59:59.999999'::TIMESTAMP
        ORDER BY RANDOM()
        LIMIT 1;
        
        -- Set default values
        v_brand := 'Brand ' || FLOOR(RANDOM() * 100)::TEXT;
        v_size := FLOOR(RANDOM() * 100 + 1)::TEXT || ' units';
        v_lead_time_days := FLOOR(RANDOM() * 14 + 1)::INTEGER;
        v_quantity_per_outer := FLOOR(RANDOM() * 20 + 1)::INTEGER;
        v_is_chiller_stock := RANDOM() < 0.2;
        v_barcode := LPAD(v_stock_item_id::TEXT, 13, '0');
        v_tax_rate := 15.0;
        v_unit_price := ROUND((RANDOM() * 100 + 1)::DECIMAL(18,2), 2);
        v_recommended_retail_price := ROUND(v_unit_price * 1.5, 2);
        v_typical_weight_per_unit := ROUND((RANDOM() * 10 + 0.1)::DECIMAL(18,3), 3);
        
        -- Insert stock item
        INSERT INTO warehouse.stock_items (
            stock_item_id, stock_item_name, supplier_id, color_id,
            unit_package_id, outer_package_id, brand, size, lead_time_days,
            quantity_per_outer, is_chiller_stock, barcode, tax_rate,
            unit_price, recommended_retail_price, typical_weight_per_unit,
            marketing_comments, internal_comments, photo, custom_fields,
            tags, search_details, last_edited_by, valid_from, valid_to
        )
        VALUES (
            v_stock_item_id, v_stock_item_name, v_supplier_id, v_color_id,
            v_unit_package_id, v_outer_package_id, v_brand, v_size, v_lead_time_days,
            v_quantity_per_outer, v_is_chiller_stock, v_barcode, v_tax_rate,
            v_unit_price, v_recommended_retail_price, v_typical_weight_per_unit,
            'New product added via simulation', NULL, NULL, NULL,
            '["new", "simulation"]'::JSONB, v_stock_item_name || ' ' || v_brand,
            v_staff_member_person_id, p_starting_when, '9999-12-31 23:59:59.999999'::TIMESTAMP
        );
        
        -- Insert stock item holding
        INSERT INTO warehouse.stock_item_holdings (
            stock_item_id, quantity_on_hand, bin_location, last_stocktake_quantity,
            last_cost_price, reorder_level, target_stock_level,
            last_edited_by, last_edited_when
        )
        VALUES (
            v_stock_item_id, 100, 'A-1-1', 100,
            v_unit_price * 0.6, 10, 100,
            v_staff_member_person_id, p_starting_when
        );
        
        v_counter := v_counter + 1;
    END LOOP;
END;
$$;

COMMENT ON PROCEDURE dataload_simulation.add_stock_items IS 'Simulates adding new stock items';
